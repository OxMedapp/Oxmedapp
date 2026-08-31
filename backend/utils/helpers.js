const crypto = require('crypto');
const db = require('../db');

function nowISO() {
  return new Date().toISOString();
}

function generateId() {
  return crypto.randomUUID();
}

function generateCode(prefix) {
  const randomPart = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `${prefix}-${randomPart}`;
}

function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

function sanitizeUser(user) {
  if (!user) return null;
  const { password_hash, verification_code, ...rest } = user;
  return rest;
}

function checkIdempotency(table, key) {
  if (!key) return null;
  return db.prepare(`SELECT * FROM ${table} WHERE idempotency_key = ?`).get(key);
}

function auditLog(entityType, entityId, action, actorId, actorRole, details = {}) {
  const id = generateId();
  db.prepare(`
    INSERT INTO audit_logs (id, entity_type, entity_id, action, actor_id, actor_role, details_json, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).run(id, entityType, entityId, action, actorId || null, actorRole || null, JSON.stringify(details), nowISO());
}

module.exports = { nowISO, generateId, generateCode, asyncHandler, sanitizeUser, checkIdempotency, auditLog };