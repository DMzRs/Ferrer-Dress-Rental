# Email OTP Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship two callable Cloud Functions (`requestEmailOtp`, `verifyEmailOtp`) backed by Firestore `emailOtps/*` and Gmail SMTP.

**Architecture:** Node 20 functions v2 (`onCall`), Admin SDK for Firestore, Nodemailer for Gmail, SHA-256 salted hashes (no raw codes stored), secrets via Secret Manager / `.env`.

**Tech Stack:** firebase-functions v6, firebase-admin v12, nodemailer 6, Node 20, node:test for unit tests.

**Spec:** `docs/superpowers/plans/../specs/2026-09-11-email-otp-design.md` — full path `docs/superpowers/specs/2026-09-11-email-otp-design.md`.

## Global Constraints

- No raw OTP codes in logs, responses, or Firestore — hashes only.
- `emailOtps/*` denied to all clients in `firestore.rules`.
- Gmail app password only in Secret Manager (`GMAIL_PASS`) or gitignored `functions/.env` — never committed.
- Code expiry 5 minutes; resend cooldown 60 seconds; max 5 verify attempts.
- Node engine 20 in `functions/package.json`.

---

### Task 1: Scaffold `functions/`

**Files:**
- Create: `functions/package.json`
- Create: `functions/.gitignore`
- Modify: `firebase.json` (add `functions` block)

**Interfaces:**
- Consumes: nothing.
- Produces: installable functions dir; `npm run deploy` target project `ferrer-rental-shop`.

- [ ] **Step 1: Write `functions/package.json`**

```json
{
  "name": "ferrer-otp-functions",
  "private": true,
  "engines": { "node": "20" },
  "main": "index.js",
  "scripts": {
    "test": "node --test test/",
    "deploy": "firebase deploy --only functions --project ferrer-rental-shop"
  },
  "dependencies": {
    "firebase-admin": "^12.7.0",
    "firebase-functions": "^6.1.1",
    "nodemailer": "^6.9.14"
  }
}
```

- [ ] **Step 2: Write `functions/.gitignore`**

```
node_modules/
.env
```

- [ ] **Step 3: Register functions in `firebase.json`** — add top-level key:

```json
"functions": [
  {
    "source": "functions",
    "codebase": "default",
    "ignore": ["node_modules", ".git", "*.log"]
  }
]
```

- [ ] **Step 4: Install and verify**

Run: `npm install --prefix functions`
Expected: exit 0, `functions/node_modules` created (ignored by git).

- [ ] **Step 5: Commit**

```bash
git add functions/package.json functions/.gitignore firebase.json
git commit -m "feat(otp): scaffold callable functions dir"
```

---

### Task 2: OTP helper logic + unit tests

**Files:**
- Create: `functions/otp.js`
- Create: `functions/test/otp.test.js`
- Test: `functions/test/otp.test.js`

**Interfaces:**
- Consumes: nothing.
- Produces (required by Task 3, exact names):
  - `genCode() -> string` (6 digits, `crypto.randomInt(100000, 1000000)` stringified)
  - `hashCode(code: string, salt: string) -> string` (hex SHA-256 of `salt + ':' + code`)
  - `timingSafeEqualHex(a: string, b: string) -> boolean`
  - `isExpired(expiresAtMs: number, nowMs?: number) -> boolean`
  - `canResend(resendAvailableAtMs: number, nowMs?: number) -> boolean`
  - `attemptsLeft(attempts: number) -> number` (`max(0, 5 - attempts)`)
  - `normalizeEmail(email: string) -> string` (trim + lowercase; throws `Error('invalid-email')` on bad format)

- [ ] **Step 1: Write the failing test** (`functions/test/otp.test.js`)

```js
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test --prefix functions`
Expected: FAIL with `Cannot find module '../otp'`.

- [ ] **Step 3: Write minimal implementation** (`functions/otp.js`)

```js
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test --prefix functions`
Expected: PASS, 4/4 subtests.

- [ ] **Step 5: Commit**

```bash
git add functions/otp.js functions/test/otp.test.js
git commit -m "feat(otp): hashed code helpers with unit tests"
```

---

### Task 3: The two callable functions

**Files:**
- Create: `functions/index.js`
- Create: `functions/.env.example` (placeholder keys only, no secrets)

**Interfaces:**
- Consumes: `functions/otp.js` helpers from Task 2; env `GMAIL_USER`, `GMAIL_PASS`.
- Produces (called by the Flutter client in the client plan):
  - `requestEmailOtp({email}) -> {sent: true, retryAfterSeconds?: number}`
  - `verifyEmailOtp({email, code}) -> {verified: true} | throws too-many-attempts/expired/invalid-code`

- [ ] **Step 1: Write `.env.example`**

```
GMAIL_USER=you@gmail.com
GMAIL_PASS=paste-app-password-here-never-commit
```

- [ ] **Step 2: Write `functions/index.js`** (full content, no placeholders)

```js
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const otp = require('./otp');

admin.initializeApp();
const db = admin.firestore();

const CODE_TTL_MS = 5 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;

function mailer() {
  const user = process.env.GMAIL_USER;
  const pass = process.env.GMAIL_PASS;
  if (!user || !pass) throw new HttpsError('failed-precondition', 'mail-not-configured');
  return nodemailer.createTransport({ service: 'gmail', auth: { user, pass } });
}

exports.requestEmailOtp = onCall(async (request) => {
  let email;
  try {
    email = otp.normalizeEmail(request.data && request.data.email);
  } catch (_) {
    throw new HttpsError('invalid-argument', 'Enter a valid email address.');
  }
  const ref = db.collection('emailOtps').doc(Buffer.from(email).toString('base64url'));
  const now = Date.now();
  const snap = await ref.get();
  if (snap.exists && !otp.canResend(snap.get('resendAvailableAt') || 0, now)) {
    const retry = Math.ceil(((snap.get('resendAvailableAt') || now) - now) / 1000);
    throw new HttpsError('resource-exhausted', 'Wait ' + retry + 's before requesting a new code.');
  }
  const code = otp.genCode();
  const salt = otp.newSalt();
  await ref.set({
    codeHash: otp.hashCode(code, salt),
    salt,
    expiresAt: admin.firestore.Timestamp.fromMillis(now + CODE_TTL_MS),
    resendAvailableAt: admin.firestore.Timestamp.fromMillis(now + RESEND_COOLDOWN_MS),
    attempts: 0,
    verified: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  try {
    await mailer().sendMail({
      from: process.env.GMAIL_USER,
      to: email,
      subject: 'Your Ferrer verification code',
      text: 'Your Ferrer verification code is ' + code + '. It expires in 5 minutes.',
    });
  } catch (_) {
    throw new HttpsError('internal', 'Could not send the code. Try again.');
  }
  return { sent: true };
});

exports.verifyEmailOtp = onCall(async (request) => {
  let email;
  try {
    email = otp.normalizeEmail(request.data && request.data.email);
  } catch (_) {
    throw new HttpsError('invalid-argument', 'Enter a valid email address.');
  }
  const code = String((request.data && request.data.code) || '').trim();
  if (!/^[0-9]{6}$/.test(code)) throw new HttpsError('invalid-argument', 'Enter the 6-digit code.');
  const ref = db.collection('emailOtps').doc(Buffer.from(email).toString('base64url'));
  const now = Date.now();
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Code expired. Send a new one.');
  const data = snap.data();
  const expiresAt = data.expiresAt && data.expiresAt.toMillis ? data.expiresAt.toMillis() : 0;
  if (otp.isExpired(expiresAt, now)) {
    await ref.delete();
    throw new HttpsError('deadline-exceeded', 'Code expired. Send a new one.');
  }
  if ((data.attempts || 0) >= otp.MAX_ATTEMPTS) {
    await ref.delete();
    throw new HttpsError('resource-exhausted', 'Too many attempts. Request a new code.');
  }
  const ok = otp.timingSafeEqualHex(data.codeHash || '', otp.hashCode(code, data.salt || ''));
  if (!ok) {
    const attempts = (data.attempts || 0) + 1;
    if (attempts >= otp.MAX_ATTEMPTS) {
      await ref.delete();
      throw new HttpsError('resource-exhausted', 'Too many attempts. Request a new code.');
    }
    await ref.update({ attempts });
    throw new HttpsError('unauthenticated', 'Incorrect code. ' + otp.attemptsLeft(attempts) + ' attempt(s) left.');
  }
  await ref.set({ verified: true, codeHash: admin.firestore.FieldValue.delete(), salt: admin.firestore.FieldValue.delete() }, { merge: true });
  return { verified: true };
});
```

- [ ] **Step 3: Syntax-check**

Run: `node --check functions/index.js && npm test --prefix functions`
Expected: no output from check; tests PASS.

- [ ] **Step 4: Commit**

```bash
git add functions/index.js functions/.env.example
git commit -m "feat(otp): request and verify callable functions via Gmail"
```

---

### Task 4: Lock down `emailOtps`, configure secrets, deploy

**Files:**
- Modify: `firestore.rules` (append `emailOtps` block)
- Create (local only, NOT committed): `functions/.env`

**Interfaces:**
- Consumes: Task 3 functions.
- Produces: deployed functions + rules; client plan can integrate.

- [ ] **Step 1: Append to `firestore.rules`** inside `match /databases/{database}/documents {`:

```
    // Email OTP docs are server-only (Admin SDK). No client access.
    match /emailOtps/{doc} {
      allow read, write: if false;
    }
```

- [ ] **Step 2: Create local `functions/.env`** (gitignored, never commit):

```
GMAIL_USER=your-account@gmail.com
GMAIL_PASS=paste-the-16-char-app-password-here
```

Get the app password at Google Account → Security → 2-Step Verification → App passwords.

- [ ] **Step 3: Set deployed secrets**

Run: `firebase functions:secrets:set GMAIL_USER` and `firebase functions:secrets:set GMAIL_PASS` (paste when prompted; values enter Secret Manager, not the repo). Then: `firebase deploy --only firestore --project ferrer-rental-shop`.

- [ ] **Step 4: Deploy functions**

Run: `npm run deploy --prefix functions`
Expected: `Deploy complete!` with both functions listed.

- [ ] **Step 5: Smoke-test with curl/emulator or console**, then commit rules only:

```bash
git add firestore.rules
git commit -m "fix(firestore): lock emailOtps to server-only"
```

Verify `.env` is ignored: `git status --short` must NOT list `functions/.env`.
