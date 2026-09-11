const test = require('node:test');
const assert = require('node:assert/strict');
const otp = require('../otp');

test('genCode returns 6 digits', () => {
  assert.match(otp.genCode(), /^[0-9]{6}$/);
});
test('hash verifies and rejects wrong code', () => {
  const salt = 'abc123';
  const h = otp.hashCode('482913', salt);
  assert.equal(otp.timingSafeEqualHex(h, otp.hashCode('482913', salt)), true);
  assert.equal(otp.timingSafeEqualHex(h, otp.hashCode('000000', salt)), false);
});
test('expiry and cooldown math', () => {
  const now = Date.now();
  assert.equal(otp.isExpired(now - 1, now), true);
  assert.equal(otp.isExpired(now + 60000, now), false);
  assert.equal(otp.canResend(now - 1, now), true);
  assert.equal(otp.canResend(now + 10000, now), false);
  assert.equal(otp.attemptsLeft(3), 2);
});
test('normalizeEmail trims, lowercases, rejects junk', () => {
  assert.equal(otp.normalizeEmail('  Jane@X.com '), 'jane@x.com');
  assert.throws(() => otp.normalizeEmail('not-an-email'), /invalid-email/);
});
