const router = require('express').Router();
const db = require('../db');
const { asyncHandler, generateId, generateCode, nowISO, auditLog } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');

router.use(authenticate);

// GET /api/patients - list all patients (masked)
router.get('/', (req, res) => {
  const patients = db.prepare(`
    SELECT id, temporary_token, phone, nhis_number, ghana_card, other_identifier, consent_status, created_at
    FROM patients
    ORDER BY created_at DESC
    LIMIT 50
  `).all();

  const masked = patients.map(p => ({
    ...p,
    phone: p.phone ? p.phone.replace(/(\d{3})\d+(\d{2})/, '$1***$2') : null,
    nhis_number: p.nhis_number ? '****' + p.nhis_number.slice(-4) : null,
    ghana_card: p.ghana_card ? '****' + p.ghana_card.slice(-4) : null,
    other_identifier: p.other_identifier ? '****' + p.other_identifier.slice(-4) : null,
  }));

  res.json({ patients: masked });
});

// GET /api/patients/search - search patients by identifiers
router.get('/search', (req, res) => {
  const { query } = req.query;
  if (!query) {
    return res.status(400).json({ error: 'query parameter is required' });
  }

  const patients = db.prepare(`
    SELECT id, temporary_token, phone, nhis_number, ghana_card, other_identifier, consent_status
    FROM patients
    WHERE phone = ? OR nhis_number = ? OR ghana_card = ? OR other_identifier = ?
    LIMIT 10
  `).all(query, query, query, query);

  const masked = patients.map(p => ({
    ...p,
    phone: p.phone ? p.phone.replace(/(\d{3})\d+(\d{2})/, '$1***$2') : null,
    nhis_number: p.nhis_number ? '****' + p.nhis_number.slice(-4) : null,
    ghana_card: p.ghana_card ? '****' + p.ghana_card.slice(-4) : null,
    other_identifier: p.other_identifier ? '****' + p.other_identifier.slice(-4) : null,
  }));

  res.json({ patients: masked });
});

// POST /api/patients - register a new patient
router.post('/', requireRole('pharmacy', 'admin'), asyncHandler(async (req, res) => {
  const { phone, nhis_number, ghana_card, other_identifier, consent_status, has_identifier } = req.body;
  if (!phone && !nhis_number && !ghana_card && !other_identifier && !has_identifier) {
    return res.status(400).json({ error: 'At least one identifier or has_identifier=false is required' });
  }

  const id = generateId();
  const temporary_token = generateCode('PT');
  const finalConsent = consent_status || 'pending';

  db.prepare(`
    INSERT INTO patients (id, temporary_token, phone, nhis_number, ghana_card, other_identifier, has_identifier, consent_status, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(id, temporary_token, phone || null, nhis_number || null, ghana_card || null, other_identifier || null, has_identifier ? 1 : 0, finalConsent, nowISO(), nowISO());

  auditLog('patient', id, 'create', req.user.id, req.user.role);
  res.status(201).json({ patient: db.prepare('SELECT * FROM patients WHERE id = ?').get(id) });
}));

// GET /api/patients/token/:token - get patient by temporary token
router.get('/token/:token', (req, res) => {
  const patient = db.prepare('SELECT * FROM patients WHERE temporary_token = ?').get(req.params.token);
  if (!patient) {
    return res.status(404).json({ error: 'Patient not found' });
  }
  res.json({ patient });
});

module.exports = router;