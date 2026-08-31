const router = require('express').Router();
const QRCode = require('qrcode');
const db = require('../db');
const { asyncHandler, generateId, generateCode, nowISO, auditLog } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');

router.use(authenticate);

function canAccessEncounter(user, encounter) {
  if (user.role === 'coordinator' || user.role === 'admin') return true;
  if (user.role === 'pharmacy' && encounter && encounter.pharmacy_id === user.pharmacy_id) return true;
  return false;
}

router.post('/encounters/:id/referral', requireRole('pharmacy', 'admin'), asyncHandler(async (req, res) => {
  const encounter = db.prepare('SELECT * FROM encounters WHERE id = ?').get(req.params.id);
  if (!encounter || !canAccessEncounter(req.user, encounter)) {
    return res.status(404).json({ error: 'Encounter not found' });
  }

  // Check if assessment is confirmed
  const assessment = db.prepare('SELECT * FROM assessments WHERE encounter_id = ?').get(encounter.id);
  if (!assessment || !assessment.confirmed_output_json) {
    return res.status(400).json({ error: 'Assessment must be confirmed by a professional before referral creation' });
  }

  let category = assessment.final_decision || encounter.risk_category;
  if (!category) {
    return res.status(400).json({ error: 'No final decision/risk category found' });
  }

  const { facility_id, reason_code, follow_up_date, notes } = req.body;
  if (!facility_id) {
    return res.status(400).json({ error: 'facility_id is required' });
  }

  const facility = db.prepare('SELECT * FROM facilities WHERE id = ? AND active = 1').get(facility_id);
  if (!facility) {
    return res.status(400).json({ error: 'Facility not found or inactive' });
  }

  const referral_code = generateCode('REF');
  const qrPayload = JSON.stringify({
    referral_code,
    encounter_code: encounter.encounter_code,
    category,
    demo_rule: Boolean(assessment.ai_output_json && JSON.parse(assessment.ai_output_json).model_version?.startsWith('mock'))
  });
  const qr_code_data = await QRCode.toDataURL(qrPayload);

  const id = generateId();
  db.prepare(`
    INSERT INTO referrals (id, referral_code, encounter_id, facility_id, category, reason_code, status, qr_code_data, referred_at, follow_up_date, notes, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?, ?, ?)
  `).run(id, referral_code, encounter.id, facility_id, category, reason_code || null, qr_code_data, nowISO(), follow_up_date || null, notes || null, nowISO(), nowISO());

  auditLog('referral', id, 'create', req.user.id, req.user.role, { encounter_id: encounter.id, facility_id });
  res.status(201).json({ referral: db.prepare('SELECT * FROM referrals WHERE id = ?').get(id) });
}));

router.get('/encounters/:id/referrals', (req, res) => {
  const encounter = db.prepare('SELECT * FROM encounters WHERE id = ?').get(req.params.id);
  if (!encounter || !canAccessEncounter(req.user, encounter)) {
    return res.status(404).json({ error: 'Encounter not found' });
  }
  const referrals = db.prepare('SELECT * FROM referrals WHERE encounter_id = ? ORDER BY created_at DESC').all(encounter.id);
  res.json({ referrals });
});

router.get('/', (req, res) => {
  let query = `
    SELECT r.*, e.encounter_code, p.name as pharmacy_name, f.name as facility_name
    FROM referrals r
    JOIN encounters e ON e.id = r.encounter_id
    JOIN pharmacies p ON p.id = e.pharmacy_id
    LEFT JOIN facilities f ON f.id = r.facility_id
    WHERE 1=1
  `;
  const params = [];

  if (req.user.role === 'pharmacy') {
    query += ' AND e.pharmacy_id = ?';
    params.push(req.user.pharmacy_id);
  }

  const { status, category, pharmacy_id } = req.query;
  if (status) { query += ' AND r.status = ?'; params.push(status); }
  if (category) { query += ' AND r.category = ?'; params.push(category); }
  if (pharmacy_id) { query += ' AND e.pharmacy_id = ?'; params.push(pharmacy_id); }

  query += ' ORDER BY r.created_at DESC';
  res.json({ referrals: db.prepare(query).all(...params) });
});

router.get('/:id', (req, res) => {
  const referral = db.prepare(`
    SELECT r.*, e.encounter_code, p.name as pharmacy_name, f.name as facility_name
    FROM referrals r
    JOIN encounters e ON e.id = r.encounter_id
    JOIN pharmacies p ON p.id = e.pharmacy_id
    LEFT JOIN facilities f ON f.id = r.facility_id
    WHERE r.id = ?
  `).get(req.params.id);

  if (!referral) {
    return res.status(404).json({ error: 'Referral not found' });
  }
  if (req.user.role === 'pharmacy') {
    const encounter = db.prepare('SELECT pharmacy_id FROM encounters WHERE id = ?').get(referral.encounter_id);
    if (!encounter || encounter.pharmacy_id !== req.user.pharmacy_id) {
      return res.status(404).json({ error: 'Referral not found' });
    }
  }

  const follow_ups = db.prepare('SELECT * FROM follow_ups WHERE referral_id = ?').all(req.params.id);
  res.json({ referral, follow_ups });
});

router.put('/:id/status', requireRole('pharmacy', 'coordinator', 'admin'), asyncHandler(async (req, res) => {
  const referral = db.prepare('SELECT * FROM referrals WHERE id = ?').get(req.params.id);
  if (!referral) {
    return res.status(404).json({ error: 'Referral not found' });
  }
  if (req.user.role === 'pharmacy') {
    const encounter = db.prepare('SELECT pharmacy_id FROM encounters WHERE id = ?').get(referral.encounter_id);
    if (!encounter || encounter.pharmacy_id !== req.user.pharmacy_id) {
      return res.status(404).json({ error: 'Referral not found' });
    }
  }

  const { status } = req.body;
  if (!['pending', 'accepted', 'completed', 'declined'].includes(status)) {
    return res.status(400).json({ error: 'status must be pending, accepted, completed or declined' });
  }

  db.prepare('UPDATE referrals SET status = ?, updated_at = ? WHERE id = ?').run(status, nowISO(), req.params.id);
  auditLog('referral', req.params.id, 'status_update', req.user.id, req.user.role, { status });
  res.json({ referral: db.prepare('SELECT * FROM referrals WHERE id = ?').get(req.params.id) });
}));

router.post('/:id/follow-up', requireRole('pharmacy', 'admin'), asyncHandler(async (req, res) => {
  const referral = db.prepare('SELECT * FROM referrals WHERE id = ?').get(req.params.id);
  if (!referral) {
    return res.status(404).json({ error: 'Referral not found' });
  }
  if (req.user.role === 'pharmacy') {
    const encounter = db.prepare('SELECT pharmacy_id FROM encounters WHERE id = ?').get(referral.encounter_id);
    if (!encounter || encounter.pharmacy_id !== req.user.pharmacy_id) {
      return res.status(404).json({ error: 'Referral not found' });
    }
  }

  const { scheduled_date, notes } = req.body;
  if (!scheduled_date) {
    return res.status(400).json({ error: 'scheduled_date is required' });
  }

  const id = generateId();
  db.prepare(`
    INSERT INTO follow_ups (id, referral_id, encounter_id, scheduled_date, outcome, notes, created_at, updated_at)
    VALUES (?, ?, ?, ?, 'pending', ?, ?, ?)
  `).run(id, referral.id, referral.encounter_id, scheduled_date, notes || null, nowISO(), nowISO());

  if (!referral.follow_up_date) {
    db.prepare('UPDATE referrals SET follow_up_date = ?, updated_at = ? WHERE id = ?').run(scheduled_date, nowISO(), referral.id);
  }

  auditLog('follow_up', id, 'create', req.user.id, req.user.role, { referral_id: referral.id });
  res.status(201).json({ follow_up: db.prepare('SELECT * FROM follow_ups WHERE id = ?').get(id) });
}));

router.put('/follow-ups/:id', requireRole('pharmacy', 'coordinator', 'admin'), asyncHandler(async (req, res) => {
  const followUp = db.prepare('SELECT * FROM follow_ups WHERE id = ?').get(req.params.id);
  if (!followUp) {
    return res.status(404).json({ error: 'Follow-up not found' });
  }
  const referral = db.prepare('SELECT * FROM referrals WHERE id = ?').get(followUp.referral_id);
  if (req.user.role === 'pharmacy') {
    const encounter = db.prepare('SELECT pharmacy_id FROM encounters WHERE id = ?').get(referral.encounter_id);
    if (!encounter || encounter.pharmacy_id !== req.user.pharmacy_id) {
      return res.status(404).json({ error: 'Follow-up not found' });
    }
  }

  const { outcome, notes } = req.body;
  const newOutcome = outcome || followUp.outcome;
  if (newOutcome && !['pending', 'completed', 'missed'].includes(newOutcome)) {
    return res.status(400).json({ error: 'outcome must be pending, completed or missed' });
  }

  const completed_at = newOutcome === 'completed' ? nowISO() : followUp.completed_at;
  db.prepare(`
    UPDATE follow_ups
    SET outcome = ?, notes = ?, completed_at = ?, updated_at = ?
    WHERE id = ?
  `).run(newOutcome, notes || followUp.notes, completed_at, nowISO(), req.params.id);

  auditLog('follow_up', req.params.id, 'update', req.user.id, req.user.role, { outcome: newOutcome });
  res.json({ follow_up: db.prepare('SELECT * FROM follow_ups WHERE id = ?').get(req.params.id) });
}));

module.exports = router;