const router = require('express').Router();
const db = require('../db');
const { asyncHandler, generateId, nowISO, checkIdempotency, auditLog } = require('../utils/helpers');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.post('/', asyncHandler(async (req, res) => {
  const { referral_id, event_type, device_id, data, idempotency_key } = req.body;
  if (!referral_id || !event_type) {
    return res.status(400).json({ error: 'referral_id and event_type are required' });
  }

  if (idempotency_key) {
    const existing = checkIdempotency('referral_events', idempotency_key);
    if (existing) {
      return res.status(200).json({ event: existing, duplicate: true });
    }
  }

  const referral = db.prepare('SELECT * FROM referrals WHERE id = ?').get(referral_id);
  if (!referral) {
    return res.status(404).json({ error: 'Referral not found' });
  }

  const eventId = generateId();
  db.prepare(`
    INSERT INTO referral_events (id, referral_id, event_type, actor_id, actor_role, device_id, timestamp, data_json, sync_status, idempotency_key)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'synced', ?)
  `).run(eventId, referral_id, event_type, req.user.id, req.user.role, device_id || null, nowISO(), data ? JSON.stringify(data) : null, idempotency_key || null);

  auditLog('referral_event', eventId, 'create', req.user.id, req.user.role, { referral_id, event_type });
  res.status(201).json({ event: db.prepare('SELECT * FROM referral_events WHERE id = ?').get(eventId) });
}));

router.get('/referrals/:referralId', (req, res) => {
  const referral = db.prepare('SELECT * FROM referrals WHERE id = ?').get(req.params.referralId);
  if (!referral) {
    return res.status(404).json({ error: 'Referral not found' });
  }
  if (req.user.role === 'pharmacy') {
    const encounter = db.prepare('SELECT pharmacy_id FROM encounters WHERE id = ?').get(referral.encounter_id);
    if (!encounter || encounter.pharmacy_id !== req.user.pharmacy_id) {
      return res.status(403).json({ error: 'Forbidden' });
    }
  }

  const events = db.prepare('SELECT * FROM referral_events WHERE referral_id = ? ORDER BY timestamp ASC').all(req.params.referralId);
  res.json({ events });
});

module.exports = router;