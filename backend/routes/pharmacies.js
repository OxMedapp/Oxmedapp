const router = require('express').Router();
const db = require('../db');
const { asyncHandler, generateId, nowISO, auditLog } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');

router.use(authenticate);

router.get('/', (req, res) => {
  const pharmacies = db.prepare('SELECT * FROM pharmacies WHERE active = 1').all();
  res.json({ pharmacies });
});

router.post('/', requireRole('admin'), asyncHandler(async (req, res) => {
  const { name, region, district, address, phone } = req.body;
  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  const id = generateId();
  db.prepare(`
    INSERT INTO pharmacies (id, name, region, district, address, phone, active, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)
  `).run(id, name, region || null, district || null, address || null, phone || null, nowISO(), nowISO());

  auditLog('pharmacy', id, 'create', req.user.id, 'admin');
  res.status(201).json({ pharmacy: db.prepare('SELECT * FROM pharmacies WHERE id = ?').get(id) });
}));

router.put('/:id', requireRole('admin'), asyncHandler(async (req, res) => {
  const pharmacy = db.prepare('SELECT * FROM pharmacies WHERE id = ?').get(req.params.id);
  if (!pharmacy) {
    return res.status(404).json({ error: 'Pharmacy not found' });
  }

  const { name, region, district, address, phone, active } = req.body;
  db.prepare(`
    UPDATE pharmacies
    SET name = ?, region = ?, district = ?, address = ?, phone = ?, active = ?, updated_at = ?
    WHERE id = ?
  `).run(
    name || pharmacy.name,
    region || pharmacy.region,
    district || pharmacy.district,
    address || pharmacy.address,
    phone || pharmacy.phone,
    active === undefined ? pharmacy.active : (active ? 1 : 0),
    nowISO(),
    pharmacy.id
  );

  auditLog('pharmacy', pharmacy.id, 'update', req.user.id, 'admin');
  res.json({ pharmacy: db.prepare('SELECT * FROM pharmacies WHERE id = ?').get(pharmacy.id) });
}));

module.exports = router;