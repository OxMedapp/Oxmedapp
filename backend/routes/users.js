const router = require('express').Router();
const bcrypt = require('bcryptjs');
const db = require('../db');
const { asyncHandler, generateId, nowISO, sanitizeUser, auditLog } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');

router.use(authenticate);
router.use(requireRole('admin'));

router.get('/', (req, res) => {
  const users = db.prepare(`
    SELECT u.*, p.name as pharmacy_name
    FROM users u
    LEFT JOIN pharmacies p ON p.id = u.pharmacy_id
    ORDER BY u.created_at DESC
  `).all();
  res.json({ users: users.map(sanitizeUser) });
});

// Approve a pending professional account
router.put('/:id/approve', asyncHandler(async (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  if (user.status !== 'pending_professional') {
    return res.status(400).json({ error: 'User is not pending professional verification' });
  }

  db.prepare('UPDATE users SET status = ?, updated_at = ? WHERE id = ?').run('active', nowISO(), user.id);
  auditLog('user', user.id, 'approved', req.user.id, 'admin');

  res.json({ user: sanitizeUser(db.prepare('SELECT * FROM users WHERE id = ?').get(user.id)) });
}));

// Create user (admin) - for immediate active accounts
router.post('/', asyncHandler(async (req, res) => {
  const { email, password, full_name, role, pharmacy_id, mobile, pharmacy_council_number, facility_license_number } = req.body;
  if (!email || !password || !full_name || !role) {
    return res.status(400).json({ error: 'email, password, full_name and role are required' });
  }
  if (!['admin', 'coordinator', 'pharmacy'].includes(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }

  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
  if (existing) {
    return res.status(409).json({ error: 'Email already exists' });
  }

  const id = generateId();
  const password_hash = bcrypt.hashSync(password, 10);
  db.prepare(`
    INSERT INTO users (id, email, password_hash, full_name, role, pharmacy_id, mobile, pharmacy_council_number, facility_license_number, status, active, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', 1, ?, ?)
  `).run(id, email, password_hash, full_name, role, pharmacy_id || null, mobile || null, pharmacy_council_number || null, facility_license_number || null, nowISO(), nowISO());

  auditLog('user', id, 'create', req.user.id, 'admin', { email, role });
  res.status(201).json({ user: sanitizeUser(db.prepare('SELECT * FROM users WHERE id = ?').get(id)) });
}));

// Update user
router.put('/:id', asyncHandler(async (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }

  const { full_name, role, pharmacy_id, active, password, status } = req.body;
  const newRole = role || user.role;
  if (newRole && !['admin', 'coordinator', 'pharmacy'].includes(newRole)) {
    return res.status(400).json({ error: 'Invalid role' });
  }

  const password_hash = password ? bcrypt.hashSync(password, 10) : user.password_hash;

  db.prepare(`
    UPDATE users
    SET full_name = ?, role = ?, pharmacy_id = ?, active = ?, password_hash = ?, status = ?, updated_at = ?
    WHERE id = ?
  `).run(
    full_name || user.full_name,
    newRole,
    pharmacy_id || user.pharmacy_id,
    active === undefined ? user.active : (active ? 1 : 0),
    password_hash,
    status || user.status,
    nowISO(),
    user.id
  );

  auditLog('user', user.id, 'update', req.user.id, 'admin', { updates: req.body });
  res.json({ user: sanitizeUser(db.prepare('SELECT * FROM users WHERE id = ?').get(user.id)) });
}));

module.exports = router;