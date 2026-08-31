const router = require('express').Router();
const db = require('../db');
const { asyncHandler, generateId, generateCode, nowISO, auditLog } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');
const { evaluateRisk } = require('../utils/ruleEngine');

router.use(authenticate);

function canAccessEncounter(user, encounter) {
  if (user.role === 'coordinator' || user.role === 'admin') return true;
  if (user.role === 'pharmacy' && encounter && encounter.pharmacy_id === user.pharmacy_id) return true;
  return false;
}

router.post('/', requireRole('pharmacy', 'admin'), asyncHandler(async (req, res) => {
  const { pharmacy_id, client_reference, age_group, sex, consent_status } = req.body;

  let finalPharmacyId = pharmacy_id;
  if (req.user.role === 'pharmacy') {
    finalPharmacyId = req.user.pharmacy_id;
  }
  if (!finalPharmacyId) {
    return res.status(400).json({ error: 'pharmacy_id is required' });
  }

  const pharmacy = db.prepare('SELECT id FROM pharmacies WHERE id = ? AND active = 1').get(finalPharmacyId);
  if (!pharmacy) {
    return res.status(400).json({ error: 'Pharmacy not found or inactive' });
  }

  const id = generateId();
  const encounter_code = generateCode('ENC');
  const finalConsent = consent_status || 'pending';

  db.prepare(`
    INSERT INTO encounters (id, encounter_code, pharmacy_id, user_id, client_reference, age_group, sex, consent_status, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(id, encounter_code, finalPharmacyId, req.user.id, client_reference || null, age_group || null, sex || null, finalConsent, nowISO(), nowISO());

  auditLog('encounter', id, 'create', req.user.id, req.user.role, { pharmacy_id: finalPharmacyId });
  res.status(201).json({ encounter: db.prepare('SELECT * FROM encounters WHERE id = ?').get(id) });
}));

router.get('/', (req, res) => {
  let query = `
    SELECT e.*, p.name as pharmacy_name, u.full_name as created_by_name,
           (SELECT COUNT(*) FROM observations o WHERE o.encounter_id = e.id) as observation_count
    FROM encounters e
    JOIN pharmacies p ON p.id = e.pharmacy_id
    JOIN users u ON u.id = e.user_id
    WHERE 1=1
  `;
  const params = [];

  if (req.user.role === 'pharmacy') {
    query += ' AND e.pharmacy_id = ?';
    params.push(req.user.pharmacy_id);
  }

  const { pharmacy_id, status, risk_category } = req.query;
  if (pharmacy_id) { query += ' AND e.pharmacy_id = ?'; params.push(pharmacy_id); }
  if (status) { query += ' AND e.status = ?'; params.push(status); }
  if (risk_category) { query += ' AND e.risk_category = ?'; params.push(risk_category); }

  query += ' ORDER BY e.created_at DESC';
  const encounters = db.prepare(query).all(...params);
  res.json({ encounters });
});

router.get('/:id', (req, res) => {
  const encounter = db.prepare('SELECT * FROM encounters WHERE id = ?').get(req.params.id);
  if (!encounter || !canAccessEncounter(req.user, encounter)) {
    return res.status(404).json({ error: 'Encounter not found' });
  }

  const observations = db.prepare('SELECT * FROM observations WHERE encounter_id = ? ORDER BY recorded_at ASC, reading_order ASC').all(req.params.id);
  const referrals = db.prepare('SELECT * FROM referrals WHERE encounter_id = ?').all(req.params.id);
  const assessment = db.prepare('SELECT * FROM assessments WHERE encounter_id = ?').get(req.params.id);
  res.json({ encounter, observations, referrals, assessment });
});

router.put('/:id/consent', requireRole('pharmacy', 'admin'), asyncHandler(async (req, res) => {
  const encounter = db.prepare('SELECT * FROM encounters WHERE id = ?').get(req.params.id);
  if (!encounter || !canAccessEncounter(req.user, encounter)) {
    return res.status(404).json({ error: 'Encounter not found' });
  }

  const { consent_status } = req.body;
  if (!['pending', 'granted', 'declined'].includes(consent_status)) {
    return res.status(400).json({ error: 'consent_status must be pending, granted or declined' });
  }

  db.prepare('UPDATE encounters SET consent_status = ?, consent_recorded_at = ?, updated_at = ? WHERE id = ?')
    .run(consent_status, nowISO(), nowISO(), encounter.id);

  auditLog('encounter', encounter.id, 'consent_update', req.user.id, req.user.role, { consent_status });
  res.json({ encounter: db.prepare('SELECT * FROM encounters WHERE id = ?').get(encounter.id) });
}));

router.post('/:id/observations', requireRole('pharmacy', 'admin'), asyncHandler(async (req, res) => {
  const encounter = db.prepare('SELECT * FROM encounters WHERE id = ?').get(req.params.id);
  if (!encounter || !canAccessEncounter(req.user, encounter)) {
    return res.status(404).json({ error: 'Encounter not found' });
  }

  const { type, value, unit, is_repeat } = req.body;
  if (!type || value === undefined) {
    return res.status(400).json({ error: 'type and value are required' });
  }

  const value_numeric = Number(value);
  const finalNumeric = Number.isFinite(value_numeric) ? value_numeric : null;
  const finalText = finalNumeric === null ? String(value) : null;

  const existingCount = db.prepare('SELECT COUNT(*) as count FROM observations WHERE encounter_id = ? AND type = ?')
    .get(encounter.id, type).count;

  const id = generateId();
  const reading_order = is_repeat ? existingCount + 1 : 1;

  db.prepare(`
    INSERT INTO observations (id, encounter_id, type, value_numeric, value_text, unit, reading_order, is_repeat, recorded_at, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(id, encounter.id, type, finalNumeric, finalText, unit || null, reading_order, is_repeat ? 1 : 0, nowISO(), nowISO());

  auditLog('observation', id, 'create', req.user.id, req.user.role, { encounter_id: encounter.id, type });
  res.status(201).json({ observation: db.prepare('SELECT * FROM observations WHERE id = ?').get(id) });
}));

router.get('/:id/observations', (req, res) => {
  const encounter = db.prepare('SELECT * FROM encounters WHERE id = ?').get(req.params.id);
  if (!encounter || !canAccessEncounter(req.user, encounter)) {
    return res.status(404).json({ error: 'Encounter not found' });
  }
  const observations = db.prepare('SELECT * FROM observations WHERE encounter_id = ? ORDER BY recorded_at ASC, reading_order ASC').all(encounter.id);
  res.json({ observations });
});

router.post('/:id/assess-risk', requireRole('pharmacy', 'admin'), asyncHandler(async (req, res) => {
  const encounter = db.prepare('SELECT * FROM encounters WHERE id = ?').get(req.params.id);
  if (!encounter || !canAccessEncounter(req.user, encounter)) {
    return res.status(404).json({ error: 'Encounter not found' });
  }

  const result = evaluateRisk(encounter.id);
  if (!result) {
    return res.status(400).json({ error: 'No observations recorded for this encounter' });
  }

  db.prepare('UPDATE encounters SET risk_category = ?, risk_rule_id = ?, risk_is_demo = ?, updated_at = ? WHERE id = ?')
    .run(result.category, result.rule_id, result.is_demo ? 1 : 0, nowISO(), encounter.id);

  auditLog('encounter', encounter.id, 'risk_assessment', req.user.id, req.user.role, { result });
  res.json({
    risk: result,
    message: result.is_demo ? 'DEMONSTRATION RULE applied. This is not clinically approved guidance.' : 'Approved clinical rule applied.'
  });
}));

module.exports = router;