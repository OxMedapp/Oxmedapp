const router = require('express').Router();
const db = require('../db');
const { nowISO } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');

router.use(authenticate);
router.use(requireRole('pharmacy', 'coordinator', 'admin'));

router.get('/coordinator', (req, res) => {
  const totalEncounters = db.prepare('SELECT COUNT(*) as count FROM encounters').get().count;
  const encountersByCategory = db.prepare(`
    SELECT risk_category, COUNT(*) as count
    FROM encounters
    WHERE risk_category IS NOT NULL
    GROUP BY risk_category
  `).all();

  const totalReferrals = db.prepare('SELECT COUNT(*) as count FROM referrals').get().count;
  const referralsByStatus = db.prepare('SELECT status, COUNT(*) as count FROM referrals GROUP BY status').all();
  const referralsByCategory = db.prepare('SELECT category, COUNT(*) as count FROM referrals GROUP BY category').all();

  const totalFollowUps = db.prepare('SELECT COUNT(*) as count FROM follow_ups').get().count;
  const followUpsByOutcome = db.prepare('SELECT outcome, COUNT(*) as count FROM follow_ups GROUP BY outcome').all();

  const encountersWithoutReferral = db.prepare(`
    SELECT COUNT(*) as count
    FROM encounters e
    WHERE e.risk_category IN ('urgent', 'emergency')
      AND NOT EXISTS (SELECT 1 FROM referrals r WHERE r.encounter_id = e.id)
  `).get().count;

  const pendingReferralsOverdue = db.prepare(`
    SELECT COUNT(*) as count
    FROM referrals r
    WHERE r.status = 'pending'
      AND r.follow_up_date IS NOT NULL
      AND r.follow_up_date < ?
  `).get(nowISO()).count;

  const encountersByPharmacy = db.prepare(`
    SELECT p.id as pharmacy_id, p.name as pharmacy_name, COUNT(e.id) as encounters
    FROM pharmacies p
    LEFT JOIN encounters e ON e.pharmacy_id = p.id
    WHERE p.active = 1
    GROUP BY p.id, p.name
  `).all();

  res.json({
    stats: {
      total_encounters: totalEncounters,
      encounters_by_category: encountersByCategory,
      total_referrals: totalReferrals,
      referrals_by_status: referralsByStatus,
      referrals_by_category: referralsByCategory,
      total_follow_ups: totalFollowUps,
      follow_ups_by_outcome: followUpsByOutcome,
      operational_gaps: {
        encounters_without_referral: encountersWithoutReferral,
        pending_referrals_overdue: pendingReferralsOverdue
      },
      encounters_by_pharmacy: encountersByPharmacy
    }
  });
});

module.exports = router;