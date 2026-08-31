// services/aiService.js
const crypto = require('crypto');

// Simple in‑memory cache (TTL 1 hour)
const cache = new Map();
const CACHE_TTL = 60 * 60 * 1000;

class BaseAIService {
  async generateReview(assessmentData) {
    throw new Error('Not implemented');
  }
}

// ---------- Mock (only for development) ----------
class MockAIService extends BaseAIService {
  async generateReview(data) {
    // deterministic mock (same as before)
    const chiefComplaint = data.chief_complaint || 'unspecified complaint';
    const duration = data.complaint_duration ? ` for ${data.complaint_duration}` : '';
    const symptoms = data.symptom_severity
      ? Object.entries(data.symptom_severity)
          .map(([symptom, severity]) => `${symptom} (severity ${severity}/5)`)
          .join(', ')
      : 'none reported';
    const meds = data.current_medication || 'none';
    const allergies = data.allergies || 'none';
    const redFlags = data.red_flags || [];

    const detectedWarningSigns = [];
    if (redFlags.includes('chest_pain')) detectedWarningSigns.push('Chest pain reported');
    if (data.bp_systolic && data.bp_systolic >= 180) detectedWarningSigns.push('Severe hypertension (systolic >= 180)');
    if (data.bp_diastolic && data.bp_diastolic >= 100) detectedWarningSigns.push('Severe hypertension (diastolic >= 100)');
    if (data.blood_glucose && (data.blood_glucose < 3.0 || data.blood_glucose > 22.0)) detectedWarningSigns.push('Critical blood glucose level');

    const missingQuestions = [];
    if (!data.bp_systolic) missingQuestions.push('Blood pressure (systolic)');
    if (!data.blood_glucose) missingQuestions.push('Blood glucose');
    if (!data.current_medication) missingQuestions.push('Current medication');
    if (!data.allergies) missingQuestions.push('Allergies');

    let suggestedUrgency = 'routine';
    if (detectedWarningSigns.some(s => s.includes('chest pain') || s.includes('Severe') || s.includes('Critical'))) {
      suggestedUrgency = 'emergency';
    } else if (data.bp_systolic >= 160 || data.blood_glucose >= 11) {
      suggestedUrgency = 'urgent';
    }

    const recommendedServiceType = suggestedUrgency === 'emergency' ? 'emergency' : (suggestedUrgency === 'urgent' ? 'urgent care' : 'general');

    const draftSummary = `Patient presents with ${chiefComplaint}${duration}. Symptoms: ${symptoms}. Current medications: ${meds}. Allergies: ${allergies}. Red flags: ${detectedWarningSigns.join('; ') || 'none'}.`;

    return {
      draft_summary: draftSummary,
      detected_warning_signs: detectedWarningSigns,
      missing_questions: missingQuestions,
      suggested_urgency: suggestedUrgency,
      recommended_service_type: recommendedServiceType,
      explanation: 'Mock AI explanation: urgency determined by deterministic red flags.',
      confidence: 0.8,
      model_version: 'mock-ai-v1',
      prompt_version: 'mock-prompt-v1',
    };
  }
}

// ---------- Gemini REST API (using gemini-3.6-flash) ----------
class GeminiAIService extends BaseAIService {
  async generateReview(data) {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error('GEMINI_API_KEY is required');
    }

    const cacheKey = crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');
    const cached = cache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
      return cached.value;
    }

    // Use model from env, default to gemini-3.6-flash (tested working)
    const modelName = process.env.GEMINI_MODEL || 'gemini-3.6-flash';
    const apiKey = process.env.GEMINI_API_KEY;
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

    const prompt = this.buildPrompt(data);
    const maxRetries = 3;
    let lastError;

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        const response = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }]
          })
        });

        if (!response.ok) {
          const errorBody = await response.text();
          throw new Error(`HTTP ${response.status}: ${errorBody}`);
        }

        const result = await response.json();
        const text = result.candidates?.[0]?.content?.parts?.[0]?.text || '';

        // Robust JSON extraction
        let jsonString = text;

        // First, try to extract between first { and last }
        const start = text.indexOf('{');
        const end = text.lastIndexOf('}') + 1;
        if (start !== -1 && end !== -1 && start < end) {
          jsonString = text.substring(start, end);
        } else {
          // Try markdown code block
          const match = text.match(/```json\s*([\s\S]*?)\s*```/);
          if (match) jsonString = match[1];
        }

        const parsed = JSON.parse(jsonString);

        // Validate required fields
        const required = ['draft_summary', 'detected_warning_signs', 'missing_questions',
                          'suggested_urgency', 'recommended_service_type', 'explanation', 'confidence'];
        for (const field of required) {
          if (!(field in parsed)) {
            throw new Error(`Missing required field: ${field}`);
          }
        }
        parsed.detected_warning_signs = Array.isArray(parsed.detected_warning_signs) ? parsed.detected_warning_signs : [];
        parsed.missing_questions = Array.isArray(parsed.missing_questions) ? parsed.missing_questions : [];
        parsed.model_version = modelName;
        parsed.prompt_version = 'v1.2';

        cache.set(cacheKey, { value: parsed, timestamp: Date.now() });
        return parsed;
      } catch (err) {
        lastError = err;
        console.warn(`Gemini attempt ${attempt + 1} failed:`, err.message);
        if (attempt < maxRetries - 1) {
          await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, attempt)));
        }
      }
    }

    console.error('Gemini failed after retries, falling back to rule-based summary', lastError);
    return this.generateFallbackReview(data);
  }

  // Simplified, explicit prompt
  buildPrompt(data) {
    const { chief_complaint, complaint_duration, symptom_severity, bp_systolic, bp_diastolic,
            blood_glucose, current_medication, allergies, medical_history, is_pregnant, age_group,
            red_flags, other_symptoms, tried_treatments } = data;

    return `
You are a clinical decision support system. Based on the following patient data, output a JSON object exactly as shown below. Do not add any extra text.

Patient:
- Complaint: ${chief_complaint || 'None'}
- Duration: ${complaint_duration || 'None'}
- Severity (0-5): ${symptom_severity ? JSON.stringify(symptom_severity) : 'None'}
- Systolic BP: ${bp_systolic || '?'}
- Diastolic BP: ${bp_diastolic || '?'}
- Blood glucose: ${blood_glucose || '?'}
- Medications: ${current_medication || 'None'}
- Allergies: ${allergies || 'None'}
- History: ${medical_history || 'None'}
- Pregnant: ${is_pregnant ? 'Yes' : 'No'}
- Age group: ${age_group || 'Adult'}
- Red flags: ${red_flags ? red_flags.join(', ') : 'None'}
- Other symptoms: ${other_symptoms || 'None'}
- Treatments tried: ${tried_treatments || 'None'}

Output exactly this JSON:
{
  "draft_summary": "short clinical summary",
  "detected_warning_signs": ["warning1", "warning2"],
  "missing_questions": ["missing1"],
  "suggested_urgency": "routine",
  "recommended_service_type": "pharmacy consultation",
  "explanation": "reason",
  "confidence": 0.8
}
Only output the JSON. No extra text.
`;
  }

  generateFallbackReview(data) {
    const warningSigns = [];
    const missingInfo = [];
    let urgency = 'routine';
    let service = 'pharmacy consultation';

    if (data.bp_systolic >= 180 || data.blood_glucose < 3.0 || data.blood_glucose > 22.0) {
      warningSigns.push('Critical vital sign abnormality');
      urgency = 'emergency';
      service = 'emergency care';
    } else if (data.bp_systolic >= 160 || data.blood_glucose >= 11) {
      warningSigns.push('Significant abnormal vital sign');
      urgency = 'urgent';
      service = 'clinic referral';
    }

    if (!data.bp_systolic) missingInfo.push('Blood pressure');
    if (!data.blood_glucose) missingInfo.push('Blood glucose');
    if (!data.current_medication) missingInfo.push('Current medication list');

    const summary = `Patient presents with ${data.chief_complaint || 'unspecified complaint'}${data.complaint_duration ? ` for ${data.complaint_duration}` : ''}. ` +
      (warningSigns.length ? `Warning: ${warningSigns.join('; ')}. ` : '') +
      (missingInfo.length ? `Missing info: ${missingInfo.join(', ')}. ` : '');

    return {
      draft_summary: summary,
      detected_warning_signs: warningSigns,
      missing_questions: missingInfo,
      suggested_urgency: urgency,
      recommended_service_type: service,
      explanation: 'Rule‑based fallback summary – AI service temporarily unavailable.',
      confidence: 0.6,
      model_version: 'fallback-rule-v1',
      prompt_version: 'fallback-v1'
    };
  }
}

function getAIService() {
  const provider = process.env.AI_PROVIDER || 'mock';
  if (process.env.NODE_ENV === 'production' && provider === 'mock') {
    throw new Error('Mock AI service is not allowed in production');
  }
  if (provider === 'gemini') {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error('GEMINI_API_KEY is required when AI_PROVIDER=gemini');
    }
    return new GeminiAIService();
  }
  return new MockAIService();
}

module.exports = { getAIService, MockAIService };