const router = require('express').Router();
const db = require('../db');
const { asyncHandler, generateId, nowISO, auditLog } = require('../utils/helpers');
const { authenticate, requireRole } = require('../middleware/auth');

router.use(authenticate);

router.get('/', (req, res) => {
  const rules = db.prepare('SELECT * FROM referral_rules ORDER BY priority DESC').all();
  const parsedRules = rules.map(rule => ({
    ...rule,
    conditions: JSON.parse(rule.conditions_json),
    conditions_json: undefined
  }));
  res.json({ rules: parsedRules });
});

router.post('/', requireRole('admin'), asyncHandler(async (req, res) => {
  const { name, description, priority, logic, conditions, category, is_demo, active } = req.body;
  if (!name || !category || !conditions) {
    return res.status(400).json({ error: 'name, category and conditions are required' });
  }
  if (!['routine', 'urgent', 'emergency'].includes(category)) {
    return res.status(400).json({ error: 'category must be routine, urgent or emergency' });
  }

  const id = generateId();
  const conditionsJson = JSON.stringify(conditions);
  const finalLogic = logic || 'AND';

  db.prepare(`
    INSERT INTO referral_rules (id, name, description, priority, logic, conditions_json, category, is_demo, active, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(id, name, description || null, priority || 0, finalLogic, conditionsJson, category, is_demo ? 1 : 0, active === false ? 0 : 1, nowISO(), nowISO());

  auditLog('referral_rule', id, 'create', req.user.id, 'admin');
  res.status(201).json({ rule: { ...db.prepare('SELECT * FROM referral_rules WHERE id = ?').get(id), conditions: JSON.parse(conditionsJson), conditions_json: undefined } });
}));

router.put('/:id', requireRole('admin'), asyncHandler(async (req, res) => {
  const existing = db.prepare('SELECT * FROM referral_rules WHERE id = ?').get(req.params.id);
  if (!existing) {
    return res.status(404).json({ error: 'Rule not found' });
  }

  const { name, description, priority, logic, conditions, category, is_demo, active } = req.body;
  const newCategory = category || existing.category;
  if (newCategory && !['routine', 'urgent', 'emergency'].includes(newCategory)) {
    return res.status(400).json({ error: 'category must be routine, urgent or emergency' });
  }

  const finalConditions = conditions ? JSON.stringify(conditions) : existing.conditions_json;

  db.prepare(`
    UPDATE referral_rules
    SET name = ?, description = ?, priority = ?, logic = ?, conditions_json = ?, category = ?, is_demo = ?, active = ?, updated_at = ?
    WHERE id = ?
  `).run(
    name || existing.name,
    description || existing.description,
    priority !== undefined ? priority : existing.priority,
    logic || existing.logic,
    finalConditions,
    newCategory,
    is_demo !== undefined ? (is_demo ? 1 : 0) : existing.is_demo,
    active !== undefined ? (active ? 1 : 0) : existing.active,
    nowISO(),
    req.params.id
  );

  auditLog('referral_rule', req.params.id, 'update', req.user.id, 'admin');
  const updated = db.prepare('SELECT * FROM referral_rules WHERE id = ?').get(req.params.id);
  res.json({ rule: { ...updated, conditions: JSON.parse(updated.conditions_json), conditions_json: undefined } });
}));

module.exports = router;