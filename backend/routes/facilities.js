const router = require('express').Router();
const db = require('../db');
const { asyncHandler, generateId, nowISO, auditLog } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');

router.use(authenticate);

router.get('/', (req, res) => {
  const facilities = db.prepare('SELECT * FROM facilities WHERE active = 1').all();
  res.json({ facilities });
});

router.post('/', requireRole('admin'), asyncHandler(async (req, res) => {
  const { name, type, region, district, address, phone } = req.body;
  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  const id = generateId();
  db.prepare(`
    INSERT INTO facilities (id, name, type, region, district, address, phone, active, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
  `).run(id, name, type || null, region || null, district || null, address || null, phone || null, nowISO(), nowISO());

  auditLog('facility', id, 'create', req.user.id, 'admin');
  res.status(201).json({ facility: db.prepare('SELECT * FROM facilities WHERE id = ?').get(id) });
}));

router.put('/:id', requireRole('admin'), asyncHandler(async (req, res) => {
  const facility = db.prepare('SELECT * FROM facilities WHERE id = ?').get(req.params.id);
  if (!facility) {
    return res.status(404).json({ error: 'Facility not found' });
  }

  const { name, type, region, district, address, phone, active } = req.body;
  db.prepare(`
    UPDATE facilities
    SET name = ?, type = ?, region = ?, district = ?, address = ?, phone = ?, active = ?, updated_at = ?
    WHERE id = ?
  `).run(
    name || facility.name,
    type || facility.type,
    region || facility.region,
    district || facility.district,
    address || facility.address,
    phone || facility.phone,
    active === undefined ? facility.active : (active ? 1 : 0),
    nowISO(),
    facility.id
  );

  auditLog('facility', facility.id, 'update', req.user.id, 'admin');
  res.json({ facility: db.prepare('SELECT * FROM facilities WHERE id = ?').get(facility.id) });
}));

module.exports = router;