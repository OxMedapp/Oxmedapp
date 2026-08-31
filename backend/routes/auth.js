const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const { asyncHandler, generateId, nowISO, sanitizeUser, auditLog } = require('../utils/helpers');
const { authenticate } = require('../middleware/auth');

// Register
router.post('/register', asyncHandler(async (req, res) => {
  const {
    email, password, full_name, mobile,
    pharmacy_council_number, facility_license_number, role
  } = req.body;

  if (!email || !password || !full_name || !mobile || !pharmacy_council_number || !facility_license_number || !role) {
    return res.status(400).json({ error: 'All fields are required' });
  }
  if (!['pharmacy', 'coordinator'].includes(role)) {
    return res.status(400).json({ error: 'Role must be pharmacy or coordinator' });
  }

  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
  if (existing) {
    return res.status(409).json({ error: 'Email already exists' });
  }

  const id = generateId();
  const password_hash = bcrypt.hashSync(password, 10);
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const verification_expires_at = new Date(Date.now() + 10 * 60 * 1000).toISOString();

  db.prepare(`
    INSERT INTO users (id, email, password_hash, full_name, role, mobile, pharmacy_council_number, facility_license_number, status, verification_code, verification_expires_at, active, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending_verification', ?, ?, 1, ?, ?)
  `).run(id, email, password_hash, full_name, role, mobile, pharmacy_council_number, facility_license_number, otp, verification_expires_at, nowISO(), nowISO());

  auditLog('user', id, 'register', id, role, { email, role });

  // Send OTP via SMS/email in production; return only in dev
  const response = {
    message: 'Registration successful. Verify your account with the OTP sent to your mobile/email.',
    user: sanitizeUser(db.prepare('SELECT * FROM users WHERE id = ?').get(id))
  };
  if (process.env.NODE_ENV !== 'production') {
    response.demo_otp = otp;
  }
  res.status(201).json(response);
}));

// Verify OTP – same
router.post('/verify-otp', asyncHandler(async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).json({ error: 'Email and OTP are required' });
  }

  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  if (user.status !== 'pending_verification') {
    return res.status(400).json({ error: 'Account is not pending verification' });
  }
  if (user.verification_code !== otp) {
    return res.status(400).json({ error: 'Invalid OTP' });
  }
  if (new Date(user.verification_expires_at) < new Date()) {
    return res.status(400).json({ error: 'OTP expired' });
  }

  db.prepare(`
    UPDATE users
    SET status = 'pending_professional', verification_code = NULL, verification_expires_at = NULL, verified_at = ?, updated_at = ?
    WHERE id = ?
  `).run(nowISO(), nowISO(), user.id);

  auditLog('user', user.id, 'otp_verified', user.id, user.role);

  res.json({ message: 'OTP verified. Account pending professional verification.' });
}));

// Login – same
router.post('/login', asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  const user = db.prepare('SELECT * FROM users WHERE email = ? AND active = 1').get(email);
  if (!user || !bcrypt.compareSync(password, user.password_hash)) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  if (user.status !== 'active') {
    return res.status(403).json({ error: 'Account is not active. Please contact administrator.' });
  }

  const token = jwt.sign(
    { id: user.id, role: user.role, pharmacy_id: user.pharmacy_id },
    process.env.JWT_SECRET,
    { expiresIn: '8h' }
  );

  auditLog('user', user.id, 'login', user.id, user.role);
  res.json({ token, user: sanitizeUser(user) });
}));

// Get current user – same
router.get('/me', authenticate, (req, res) => {
  res.json({ user: sanitizeUser(req.user) });
});

module.exports = router;