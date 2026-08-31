const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'data', `test-api-${Date.now()}.db`);
if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
process.env.DB_PATH = dbPath;
process.env.SEED_DEMO = 'true';
process.env.JWT_SECRET = 'test-secret';
process.env.AI_PROVIDER = 'mock';

const app = require('../app');

function assert(condition, message) {
  if (!condition) throw new Error(message || 'Assertion failed');
}

async function main() {
  const server = app.listen(0);
  const port = server.address().port;
  const base = `http://localhost:${port}`;

  console.log(`Test server started on ${base}`);

  try {
    // Health check
    let res = await fetch(`${base}/health`);
    let data = await res.json();
    assert(res.status === 200 && data.status === 'ok', 'Health check failed');

    // Login admin
    res = await fetch(`${base}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'admin@pharmalink.demo', password: 'Admin123!' })
    });
    data = await res.json();
    assert(res.status === 200 && data.token, 'Admin login failed');
    const adminToken = data.token;

    // Register a new pharmacy user (pending OTP)
    res = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'newpharm@test.com',
        password: 'Test123!',
        full_name: 'New Pharmacist',
        mobile: '0245555555',
        pharmacy_council_number: 'PC-999',
        facility_license_number: 'FL-999',
        role: 'pharmacy'
      })
    });
    data = await res.json();
    assert(res.status === 201 && data.demo_otp, 'Registration failed');
    const otp = data.demo_otp;
    const newUserId = data.user.id;

    // Verify OTP
    res = await fetch(`${base}/api/auth/verify-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'newpharm@test.com', otp })
    });
    data = await res.json();
    assert(res.status === 200, 'OTP verification failed');

    // Approve user (admin)
    res = await fetch(`${base}/api/users/${newUserId}/approve`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${adminToken}` }
    });
    data = await res.json();
    assert(res.status === 200 && data.user.status === 'active', 'Approval failed');

    // Login as pharmacy (original demo user)
    res = await fetch(`${base}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'pharmacy@pharmalink.demo', password: 'Pharm123!' })
    });
    data = await res.json();
    assert(res.status === 200 && data.token, 'Pharmacy login failed');
    const pharmacyToken = data.token;

    // Create encounter
    res = await fetch(`${base}/api/encounters`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${pharmacyToken}` },
      body: JSON.stringify({ client_reference: 'TEST-001', consent_status: 'granted' })
    });
    data = await res.json();
    assert(res.status === 201, 'Encounter creation failed');
    const encounterId = data.encounter.id;

    // Register patient
    res = await fetch(`${base}/api/patients`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${pharmacyToken}` },
      body: JSON.stringify({ phone: '0249999999', consent_status: 'granted', has_identifier: true })
    });
    data = await res.json();
    assert(res.status === 201, 'Patient registration failed');
    const patientId = data.patient.id;

    // Create assessment
    res = await fetch(`${base}/api/assessments/encounters/${encounterId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${pharmacyToken}` },
      body: JSON.stringify({
        patient_id: patientId,
        chief_complaint: 'Test complaint',
        complaint_duration: '2 days',
        symptom_severity: { fever: 3, headache: 2 },
        bp_systolic: 185,
        bp_diastolic: 95,
        blood_glucose: 6.5,
        current_medication: 'Paracetamol',
        allergies: 'None',
        medical_history: 'None',
        is_pregnant: false,
        age_group: 'adult',
        red_flags: ['chest_pain'],
        missing_information: [],
        pharmacist_notes: '',
        final_decision: '',
        images: []
      })
    });
    data = await res.json();
    assert(res.status === 201 && data.assessment, 'Assessment creation failed');
    const assessmentId = data.assessment.id;

    // Generate AI review
    res = await fetch(`${base}/api/ai-review/encounters/${encounterId}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${pharmacyToken}` }
    });
    data = await res.json();
    assert(res.status === 200 && data.ai_review, 'AI review failed');

    // Confirm assessment
    res = await fetch(`${base}/api/assessments/${assessmentId}/confirm`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${pharmacyToken}` },
      body: JSON.stringify({ confirmed_output: data.ai_review })
    });
    data = await res.json();
    assert(res.status === 200 && data.assessment.confirmed_output_json, 'Confirmation failed');

    // Get facilities
    res = await fetch(`${base}/api/facilities`, {
      headers: { Authorization: `Bearer ${pharmacyToken}` }
    });
    data = await res.json();
    assert(res.status === 200 && data.facilities.length > 0, 'Facility list failed');
    const facilityId = data.facilities[0].id;

    // Create referral (should succeed because assessment confirmed)
    res = await fetch(`${base}/api/encounters/${encounterId}/referral`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${pharmacyToken}` },
      body: JSON.stringify({ facility_id: facilityId, reason_code: 'DEMO_EMERGENCY' })
    });
    data = await res.json();
    assert(res.status === 201 && data.referral, 'Referral creation failed');
    const referralId = data.referral.id;

    // Add referral event
    res = await fetch(`${base}/api/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${pharmacyToken}` },
      body: JSON.stringify({ referral_id: referralId, event_type: 'created', idempotency_key: 'test-key-1' })
    });
    data = await res.json();
    assert(res.status === 201 && data.event, 'Event creation failed');

    // Coordinator stats
    res = await fetch(`${base}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'coordinator@pharmalink.demo', password: 'Coord123!' })
    });
    data = await res.json();
    assert(res.status === 200, 'Coordinator login failed');
    const coordToken = data.token;

    res = await fetch(`${base}/api/stats/coordinator`, {
      headers: { Authorization: `Bearer ${coordToken}` }
    });
    data = await res.json();
    assert(res.status === 200 && data.stats, 'Stats failed');
    assert(data.stats.total_encounters >= 1, 'Stats should show encounters');

    console.log('\n✅ ALL TESTS PASSED');
  } catch (err) {
    console.error('\n❌ TEST FAILED:', err.message);
    process.exitCode = 1;
  } finally {
    server.close();
  }
}

main();