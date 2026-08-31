const router = require('express').Router();
const db = require('../db');
const { asyncHandler, auditLog } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');

router.use(authenticate);

// Rank facilities based on mock distance and capability
router.post('/rank', requireRole('pharmacy', 'admin'), asyncHandler(async (req, res) => {
  const { urgency, required_service } = req.body;
  if (!urgency || !required_service) {
    return res.status(400).json({ error: 'urgency and required_service are required' });
  }

  const facilities = db.prepare('SELECT * FROM facilities WHERE active = 1').all();
  const ranked = facilities.map(f => {
    const dist = Math.abs(f.name.length * 1.2 - 1.0);
    return {
      facility_id: f.id,
      name: f.name,
      type: f.type,
      distance_km: parseFloat(dist.toFixed(1)),
      estimated_time_min: Math.round(dist * 5),
      open_now: true,
      capability_match: true,
      ranking_reason: `Capable of ${required_service}, ${dist.toFixed(1)} km away`
    };
  }).sort((a, b) => a.distance_km - b.distance_km);

  auditLog('routing', 'batch', 'rank', req.user.id, req.user.role, { urgency, required_service });
  res.json({ facilities: ranked });
}));

module.exports = router;