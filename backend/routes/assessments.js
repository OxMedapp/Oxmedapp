const router = require('express').Router();
const db = require('../db');
const { asyncHandler, generateId, nowISO, auditLog } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');

router.use(authenticate);

// Create/update assessment for an encounter
router.post('/encounters/:encounterId', requireRole('pharmacy', 'admin'), asyncHandler(async (req, res) => {
  const encounter = db.prepare('SELECT * FROM encounters WHERE id = ?').get(req.params.encounterId);
  if (!encounter) {
    return res.status(404).json({ error: 'Encounter not found' });
  }
  if (req.user.role === 'pharmacy' && encounter.pharmacy_id !== req.user.pharmacy_id) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const {
    patient_id, chief_complaint, complaint_duration, symptom_severity,
    bp_systolic, bp_diastolic, blood_glucose, malaria_result,
    current_medication, allergies, medical_history, is_pregnant, age_group,
    red_flags, missing_information, pharmacist_notes, final_decision, images
  } = req.body;

  if (!patient_id) {
    return res.status(400).json({ error: 'patient_id is required' });
  }

  const existing = db.prepare('SELECT * FROM assessments WHERE encounter_id = ?').get(encounter.id);
  if (existing) {
    db.prepare(`
      UPDATE assessments
      SET patient_id = ?, chief_complaint = ?, complaint_duration = ?, symptom_severity_json = ?,
          bp_systolic = ?, bp_diastolic = ?, blood_glucose = ?, malaria_result = ?,
          current_medication = ?, allergies = ?, medical_history = ?, is_pregnant = ?, age_group = ?,
          red_flags_json = ?, missing_information_json = ?, pharmacist_notes = ?, final_decision = ?,
          images_json = ?, updated_at = ?
      WHERE encounter_id = ?
    `).run(
      patient_id,
      chief_complaint || null,
      complaint_duration || null,
      symptom_severity ? JSON.stringify(symptom_severity) : null,
      bp_systolic || null,
      bp_diastolic || null,
      blood_glucose || null,
      malaria_result || null,
      current_medication || null,
      allergies || null,
      medical_history || null,
      is_pregnant ? 1 : 0,
      age_group || null,
      red_flags ? JSON.stringify(red_flags) : null,
      missing_information ? JSON.stringify(missing_information) : null,
      pharmacist_notes || null,
      final_decision || null,
      images ? JSON.stringify(images) : null,
      nowISO(),
      encounter.id
    );
    auditLog('assessment', existing.id, 'update', req.user.id, req.user.role);
    return res.json({ assessment: db.prepare('SELECT * FROM assessments WHERE encounter_id = ?').get(encounter.id) });
  }

  const id = generateId();
  db.prepare(`
    INSERT INTO assessments (id, encounter_id, patient_id, chief_complaint, complaint_duration, symptom_severity_json,
      bp_systolic, bp_diastolic, blood_glucose, malaria_result, current_medication, allergies, medical_history,
      is_pregnant, age_group, red_flags_json, missing_information_json, pharmacist_notes, final_decision, images_json,
      created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    id, encounter.id, patient_id, chief_complaint || null, complaint_duration || null,
    symptom_severity ? JSON.stringify(symptom_severity) : null,
    bp_systolic || null, bp_diastolic || null, blood_glucose || null, malaria_result || null,
    current_medication || null, allergies || null, medical_history || null,
    is_pregnant ? 1 : 0, age_group || null,
    red_flags ? JSON.stringify(red_flags) : null,
    missing_information ? JSON.stringify(missing_information) : null,
    pharmacist_notes || null, final_decision || null,
    images ? JSON.stringify(images) : null,
    nowISO(), nowISO()
  );

  auditLog('assessment', id, 'create', req.user.id, req.user.role, { encounter_id: encounter.id });
  res.status(201).json({ assessment: db.prepare('SELECT * FROM assessments WHERE id = ?').get(id) });
}));

// Get assessment for encounter
router.get('/encounters/:encounterId', (req, res) => {
  const encounter = db.prepare('SELECT * FROM encounters WHERE id = ?').get(req.params.encounterId);
  if (!encounter) {
    return res.status(404).json({ error: 'Encounter not found' });
  }
  if (req.user.role === 'pharmacy' && encounter.pharmacy_id !== req.user.pharmacy_id) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const assessment = db.prepare('SELECT * FROM assessments WHERE encounter_id = ?').get(encounter.id);
  if (!assessment) {
    return res.status(404).json({ error: 'Assessment not found for this encounter' });
  }
  res.json({ assessment });
});

// Professional confirmation of AI output
router.post('/:id/confirm', requireRole('pharmacy', 'coordinator', 'admin'), asyncHandler(async (req, res) => {
  const assessment = db.prepare('SELECT * FROM assessments WHERE id = ?').get(req.params.id);
  if (!assessment) {
    return res.status(404).json({ error: 'Assessment not found' });
  }

  // Ensure user has access if pharmacy
  if (req.user.role === 'pharmacy') {
    const encounter = db.prepare('SELECT pharmacy_id FROM encounters WHERE id = ?').get(assessment.encounter_id);
    if (!encounter || encounter.pharmacy_id !== req.user.pharmacy_id) {
      return res.status(403).json({ error: 'Forbidden' });
    }
  }

  const { confirmed_output } = req.body;
  if (!confirmed_output) {
    return res.status(400).json({ error: 'confirmed_output is required' });
  }

  db.prepare(`
    UPDATE assessments
    SET confirmed_output_json = ?, confirmed_by = ?, confirmed_at = ?, updated_at = ?
    WHERE id = ?
  `).run(JSON.stringify(confirmed_output), req.user.id, nowISO(), nowISO(), assessment.id);

  auditLog('assessment', assessment.id, 'confirm', req.user.id, req.user.role, { confirmed_output });
  res.json({ assessment: db.prepare('SELECT * FROM assessments WHERE id = ?').get(assessment.id) });
}));

module.exports = router;