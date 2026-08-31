require('dotenv').config();
const { getAIService } = require('./services/aiService');

const sampleData = {
  chief_complaint: 'Severe headache and fever for 2 days',
  complaint_duration: '2 days',
  symptom_severity: { headache: 4, fever: 3 },
  bp_systolic: 160,
  bp_diastolic: 95,
  blood_glucose: 6.5,
  current_medication: 'Paracetamol',
  allergies: 'None',
  medical_history: 'None',
  is_pregnant: false,
  age_group: 'adult',
  red_flags: ['chest_pain'],
  other_symptoms: 'Nausea',
  tried_treatments: 'Paracetamol - no relief'
};

const service = getAIService();
service.generateReview(sampleData)
  .then(result => console.log(JSON.stringify(result, null, 2)))
  .catch(err => console.error('Error:', err.message));