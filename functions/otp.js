const crypto = require('node:crypto');
const MAX_ATTEMPTS = 5;

function genCode() {
  return String(crypto.randomInt(100000, 1000000));
}
function newSalt() {
  return crypto.randomBytes(16).toString('hex');
}
function hashCode(code, salt) {
  return crypto.createHash('sha256').update(salt + ':' + code, 'utf8').digest('hex');
}
function timingSafeEqualHex(a, b) {
  const ba = Buffer.from(a, 'hex');
  const bb = Buffer.from(b, 'hex');
  if (ba.length !== bb.length) return false;
  return crypto.timingSafeEqual(ba, bb);
}
function isExpired(expiresAtMs, nowMs = Date.now()) {
  return nowMs >= expiresAtMs;
}
function canResend(resendAvailableAtMs, nowMs = Date.now()) {
  return nowMs >= resendAvailableAtMs;
}
function attemptsLeft(attempts) {
  return Math.max(0, MAX_ATTEMPTS - attempts);
}
function normalizeEmail(email) {
  const v = String(email || '').trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)) throw new Error('invalid-email');
  return v;
}
module.exports = { MAX_ATTEMPTS, genCode, newSalt, hashCode, timingSafeEqualHex, isExpired, canResend, attemptsLeft, normalizeEmail };
