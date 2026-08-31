const router = require('express').Router();
const db = require('../db');
const { asyncHandler, nowISO, auditLog } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');
const { getAIService } = require('../services/aiService');

router.use(authenticate);

// Generate AI review for an assessment
router.post('/encounters/:encounterId', requireRole('pharmacy', 'admin'), asyncHandler(async (req, res) => {
  const encounter = db.prepare('SELECT * FROM encounters WHERE id = ?').get(req.params.encounterId);
  if (!encounter) {
    return res.status(404).json({ error: 'Encounter not found' });
  }
  if (req.user.role === 'pharmacy' && encounter.pharmacy_id !== req.user.pharmacy_id) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const assessment = db.prepare('SELECT * FROM assessments WHERE encounter_id = ?').get(encounter.id);
  if (!assessment) {
    return res.status(400).json({ error: 'No assessment found. Please complete assessment first.' });
  }

  // Prepare de-identified data for AI (remove patient identifiers)
  const aiInput = {
    chief_complaint: assessment.chief_complaint,
    complaint_duration: assessment.complaint_duration,
    symptom_severity: assessment.symptom_severity_json ? JSON.parse(assessment.symptom_severity_json) : {},
    bp_systolic: assessment.bp_systolic,
    bp_diastolic: assessment.bp_diastolic,
    blood_glucose: assessment.blood_glucose,
    current_medication: assessment.current_medication,
    allergies: assessment.allergies,
    medical_history: assessment.medical_history,
    is_pregnant: Boolean(assessment.is_pregnant),
    age_group: assessment.age_group,
    red_flags: assessment.red_flags_json ? JSON.parse(assessment.red_flags_json) : [],
  };

  const aiService = getAIService();
  const aiOutput = await aiService.generateReview(aiInput);

  // Store AI input/output in assessment
  db.prepare(`
    UPDATE assessments
    SET ai_input_json = ?, ai_output_json = ?, ai_model_version = ?, ai_prompt_version = ?, updated_at = ?
    WHERE id = ?
  `).run(
    JSON.stringify(aiInput),
    JSON.stringify(aiOutput),
    aiOutput.model_version || 'unknown',
    aiOutput.prompt_version || 'unknown',
    nowISO(),
    assessment.id
  );

  auditLog('assessment', assessment.id, 'ai_review', req.user.id, req.user.role, { ai_model: aiOutput.model_version });

  res.json({ ai_review: aiOutput });
}));

module.exports = router;