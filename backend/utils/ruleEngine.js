const db = require('../db');

function getLatestObservations(encounterId) {
  const rows = db.prepare(`
    SELECT type, value_numeric, value_text, unit, recorded_at, reading_order
    FROM observations
    WHERE encounter_id = ?
    ORDER BY recorded_at DESC, reading_order DESC
  `).all(encounterId);

  const map = {};
  for (const row of rows) {
    if (!map[row.type]) {
      map[row.type] = row;
    }
  }
  return map;
}

function matchesCondition(obs, condition) {
  if (!obs) return false;
  const actual = obs.value_numeric;
  const expected = Number(condition.value);
  if (actual === null || actual === undefined || Number.isNaN(actual)) {
    if (obs.value_text && condition.value_text) {
      return String(obs.value_text) === String(condition.value_text);
    }
    return false;
  }
  switch (condition.operator) {
    case '>': return actual > expected;
    case '>=': return actual >= expected;
    case '<': return actual < expected;
    case '<=': return actual <= expected;
    case '==': case '=': return actual === expected;
    case '!=': return actual !== expected;
    default: return false;
  }
}

function evaluateRule(rule, observations) {
  let conditions;
  try {
    conditions = JSON.parse(rule.conditions_json).conditions || [];
  } catch (e) {
    return false;
  }
  const results = conditions.map((cond) => matchesCondition(observations[cond.type], cond));
  const logic = (rule.logic || 'AND').toUpperCase();
  if (logic === 'OR') return results.some(Boolean);
  return results.every(Boolean);
}

function evaluateRisk(encounterId) {
  const observations = getLatestObservations(encounterId);
  if (Object.keys(observations).length === 0) return null;

  const rules = db.prepare('SELECT * FROM referral_rules WHERE active = 1 ORDER BY priority DESC').all();
  for (const rule of rules) {
    if (evaluateRule(rule, observations)) {
      return {
        category: rule.category,
        rule_id: rule.id,
        rule_name: rule.name,
        is_demo: Boolean(rule.is_demo),
        reason_code: `DEMO_${rule.category.toUpperCase()}`,
      };
    }
  }
  return {
    category: 'routine',
    rule_id: null,
    rule_name: 'Routine (demonstration fallback)',
    is_demo: true,
    reason_code: 'DEMO_FALLBACK_ROUTINE',
  };
}

module.exports = { evaluateRisk };