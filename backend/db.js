const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const dbPath = process.env.DB_PATH || './data/pharmalink.db';
fs.mkdirSync(path.dirname(dbPath), { recursive: true });

const db = new Database(dbPath);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// ------------------------------------------------------------------
// Tables
// ------------------------------------------------------------------

db.exec(`
CREATE TABLE IF NOT EXISTS pharmacies (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  region TEXT,
  district TEXT,
  address TEXT,
  phone TEXT,
  active INTEGER DEFAULT 1,
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin','coordinator','pharmacy')),
  pharmacy_id TEXT,
  mobile TEXT,
  pharmacy_council_number TEXT,
  facility_license_number TEXT,
  status TEXT DEFAULT 'active',
  verification_code TEXT,
  verification_expires_at TEXT,
  verified_at TEXT,
  active INTEGER DEFAULT 1,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id)
);

CREATE TABLE IF NOT EXISTS facilities (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT,
  region TEXT,
  district TEXT,
  address TEXT,
  phone TEXT,
  active INTEGER DEFAULT 1,
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS patients (
  id TEXT PRIMARY KEY,
  temporary_token TEXT UNIQUE NOT NULL,
  phone TEXT,
  nhis_number TEXT,
  ghana_card TEXT,
  other_identifier TEXT,
  has_identifier INTEGER DEFAULT 0,
  consent_status TEXT DEFAULT 'pending',
  consent_recorded_at TEXT,
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS referral_rules (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  priority INTEGER DEFAULT 0,
  logic TEXT DEFAULT 'AND',
  conditions_json TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('routine','urgent','emergency')),
  is_demo INTEGER DEFAULT 1,
  active INTEGER DEFAULT 1,
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE IF NOT EXISTS encounters (
  id TEXT PRIMARY KEY,
  encounter_code TEXT UNIQUE NOT NULL,
  pharmacy_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  client_reference TEXT,
  age_group TEXT,
  sex TEXT,
  consent_status TEXT DEFAULT 'pending',
  consent_recorded_at TEXT,
  risk_category TEXT,
  risk_rule_id TEXT,
  risk_is_demo INTEGER DEFAULT 0,
  status TEXT DEFAULT 'open',
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (risk_rule_id) REFERENCES referral_rules(id)
);

CREATE TABLE IF NOT EXISTS observations (
  id TEXT PRIMARY KEY,
  encounter_id TEXT NOT NULL,
  type TEXT NOT NULL,
  value_numeric REAL,
  value_text TEXT,
  unit TEXT,
  reading_order INTEGER DEFAULT 1,
  is_repeat INTEGER DEFAULT 0,
  recorded_at TEXT,
  created_at TEXT,
  FOREIGN KEY (encounter_id) REFERENCES encounters(id)
);

CREATE TABLE IF NOT EXISTS assessments (
  id TEXT PRIMARY KEY,
  encounter_id TEXT NOT NULL,
  patient_id TEXT NOT NULL,
  chief_complaint TEXT,
  complaint_duration TEXT,
  symptom_severity_json TEXT,
  bp_systolic REAL,
  bp_diastolic REAL,
  blood_glucose REAL,
  malaria_result TEXT,
  current_medication TEXT,
  allergies TEXT,
  medical_history TEXT,
  is_pregnant INTEGER DEFAULT 0,
  age_group TEXT,
  red_flags_json TEXT,
  missing_information_json TEXT,
  pharmacist_notes TEXT,
  final_decision TEXT,
  images_json TEXT,
  ai_input_json TEXT,
  ai_output_json TEXT,
  ai_model_version TEXT,
  ai_prompt_version TEXT,
  confirmed_output_json TEXT,
  confirmed_by TEXT,
  confirmed_at TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (encounter_id) REFERENCES encounters(id),
  FOREIGN KEY (patient_id) REFERENCES patients(id)
);

CREATE TABLE IF NOT EXISTS referrals (
  id TEXT PRIMARY KEY,
  referral_code TEXT UNIQUE NOT NULL,
  encounter_id TEXT NOT NULL,
  facility_id TEXT,
  category TEXT NOT NULL,
  reason_code TEXT,
  status TEXT DEFAULT 'pending',
  qr_code_data TEXT,
  referred_at TEXT,
  follow_up_date TEXT,
  notes TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (encounter_id) REFERENCES encounters(id),
  FOREIGN KEY (facility_id) REFERENCES facilities(id)
);

CREATE TABLE IF NOT EXISTS follow_ups (
  id TEXT PRIMARY KEY,
  referral_id TEXT NOT NULL,
  encounter_id TEXT NOT NULL,
  scheduled_date TEXT,
  outcome TEXT DEFAULT 'pending',
  notes TEXT,
  completed_at TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (referral_id) REFERENCES referrals(id),
  FOREIGN KEY (encounter_id) REFERENCES encounters(id)
);

CREATE TABLE IF NOT EXISTS referral_events (
  id TEXT PRIMARY KEY,
  referral_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  actor_id TEXT,
  actor_role TEXT,
  device_id TEXT,
  timestamp TEXT,
  data_json TEXT,
  sync_status TEXT DEFAULT 'pending',
  idempotency_key TEXT UNIQUE,
  FOREIGN KEY (referral_id) REFERENCES referrals(id)
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  action TEXT NOT NULL,
  actor_id TEXT,
  actor_role TEXT,
  details_json TEXT,
  created_at TEXT
);

CREATE TABLE IF NOT EXISTS sync_queue (
  id TEXT PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT,
  action TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  attempts INTEGER DEFAULT 0,
  created_at TEXT,
  updated_at TEXT,
  idempotency_key TEXT UNIQUE
);

CREATE INDEX IF NOT EXISTS idx_encounters_pharmacy ON encounters(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_observations_encounter ON observations(encounter_id);
CREATE INDEX IF NOT EXISTS idx_referrals_encounter ON referrals(encounter_id);
CREATE INDEX IF NOT EXISTS idx_followups_referral ON follow_ups(referral_id);
CREATE INDEX IF NOT EXISTS idx_assessments_encounter ON assessments(encounter_id);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_type, entity_id);
`);

// ------------------------------------------------------------------
// Seed demo data (only in non‑production unless explicitly allowed)
// ------------------------------------------------------------------

function seedDemoData() {
  const now = new Date().toISOString();

  // Pharmacies
  const insertPharmacy = db.prepare(`
    INSERT OR IGNORE INTO pharmacies (id, name, region, district, address, phone, active, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  insertPharmacy.run('pharm-p001', 'Adum Community Pharmacy', 'Ashanti', 'Kumasi', 'Adum Road', '0302000001', 1, now, now);
  insertPharmacy.run('pharm-p002', 'Osu Pharmacy', 'Greater Accra', 'Accra', 'Oxford Street', '0302000002', 1, now, now);

  // Facilities
  const insertFacility = db.prepare(`
    INSERT OR IGNORE INTO facilities (id, name, type, region, district, address, phone, active, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  insertFacility.run('fac-001', 'Kumasi Central Clinic', 'Clinic', 'Ashanti', 'Kumasi', 'Hospital Road', '0303000001', 1, now, now);
  insertFacility.run('fac-002', 'Ridge Hospital', 'Hospital', 'Greater Accra', 'Accra', 'Ridge', '0303000002', 1, now, now);

  // Users
  const insertUser = db.prepare(`
    INSERT OR IGNORE INTO users (id, email, password_hash, full_name, role, pharmacy_id, mobile, pharmacy_council_number, facility_license_number, status, active, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, ?, ?)
  `);
  const adminHash = bcrypt.hashSync('Admin123!', 10);
  const coordHash = bcrypt.hashSync('Coord123!', 10);
  const pharmHash = bcrypt.hashSync('Pharm123!', 10);

  insertUser.run('user-admin', 'admin@pharmalink.demo', adminHash, 'Demo Administrator', 'admin', null, '0240000001', 'ADMIN-001', 'LIC-001', 1, now, now);
  insertUser.run('user-coord', 'coordinator@pharmalink.demo', coordHash, 'Demo Coordinator', 'coordinator', null, '0240000002', 'COORD-001', 'LIC-002', 1, now, now);
  insertUser.run('user-pharm', 'pharmacy@pharmalink.demo', pharmHash, 'Demo Pharmacy Worker', 'pharmacy', 'pharm-p001', '0240000003', 'PC-12345', 'FL-67890', 1, now, now);

  // Patients
  const insertPatient = db.prepare(`
    INSERT OR IGNORE INTO patients (id, temporary_token, phone, nhis_number, ghana_card, other_identifier, has_identifier, consent_status, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  insertPatient.run('patient-001', 'PT-DEMO001', '0241234567', null, null, null, 1, 'granted', now, now);

  // Referral rules (demo)
  const insertRule = db.prepare(`
    INSERT OR IGNORE INTO referral_rules (id, name, description, priority, logic, conditions_json, category, is_demo, active, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const emergencyConditions = {
    logic: 'OR',
    conditions: [
      { type: 'bp_systolic', operator: '>=', value: 180 },
      { type: 'blood_glucose', operator: '<', value: 3.0 },
      { type: 'blood_glucose', operator: '>', value: 22.0 }
    ]
  };
  insertRule.run('rule-emergency', 'DEMO Emergency Referral Rule', 'Synthetic demonstration rule only. Not clinically approved.', 100, 'OR', JSON.stringify(emergencyConditions), 'emergency', 1, 1, now, now);

  const urgentConditions = {
    logic: 'OR',
    conditions: [
      { type: 'bp_systolic', operator: '>=', value: 160 },
      { type: 'bp_diastolic', operator: '>=', value: 100 },
      { type: 'blood_glucose', operator: '>=', value: 11.0 }
    ]
  };
  insertRule.run('rule-urgent', 'DEMO Urgent Referral Rule', 'Synthetic demonstration rule only. Not clinically approved.', 50, 'OR', JSON.stringify(urgentConditions), 'urgent', 1, 1, now, now);
}

// Only seed if not in production, or if SEED_DEMO is explicitly true
const isProduction = process.env.NODE_ENV === 'production';
const shouldSeed = process.env.SEED_DEMO === 'true' || (!isProduction && process.env.SEED_DEMO !== 'false');
if (shouldSeed) {
  seedDemoData();
}

module.exports = db;
module.exports.seedDemoData = seedDemoData;