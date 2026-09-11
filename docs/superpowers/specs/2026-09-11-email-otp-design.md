# Email OTP (6-Digit Code) — Signup Verification Design

Date: 2026-09-11
Status: Proposed — awaiting user review before implementation plan.
Scope: Signup-only. Login keeps email + password. Gmail SMTP via app password
stored in Functions config (never in code, chat, or git).

## 1. Goal

Verify email ownership at signup with a 6-digit code sent to the user's inbox.
Non-goals: login OTP, phone/SMS OTP, link-based sign-in, Resend migration
(documented as a future driver swap, not built now).

## 2. Architecture

```
Signup Screen (Step 1: details)
  -> requestEmailOtp(email)      [HTTPS callable, Functions + Nodemailer/Gmail]
  -> Signup Screen (Step 2: code entry, resend timer)
  -> verifyEmailOtp(email, code) [HTTPS callable, returns verification token]
  -> existing signUp() runs with verified email
```

Client never generates, stores, or sees the raw code. Secrets stay server-side.

## 3. Firestore Schema — `emailOtps/{emailKey}`

`emailKey` = lowercased trimmed email with `.`/`@` sanitized (or base64url).
Fields:

| Field              | Type      | Purpose                                              |
|--------------------|-----------|------------------------------------------------------|
| `codeHash`         | string    | SHA-256(code + per-code salt). Never the raw code.   |
| `salt`             | string    | Random 16 bytes hex.                                 |
| `expiresAt`        | timestamp | `now + 5 minutes`.                                   |
| `attempts`         | number    | Failed verify count. Max 5, then doc invalidated.    |
| `resendAvailableAt`| timestamp | `now + 60 seconds`. Enforces resend cooldown.        |
| `verified`         | boolean   | Set true on success; signup checks it (or token).    |
| `createdAt`        | timestamp | Audit / cleanup.                                     |

Security rules: deny all client reads/writes on `emailOtps/*`. Functions use
the Admin SDK and bypass rules. Add the deny block to `firestore.rules`.

## 4. Cloud Functions (`functions/`, Node 20)

- `requestEmailOtp({email})`
  1. Validate email format; normalize lowercase/trim.
  2. Read existing doc: if `resendAvailableAt > now`, return throttled error
     with `retryAfterSeconds` (no code sent).
  3. Generate 6 digits via `crypto.randomInt(100000, 999999)`.
  4. Salt + SHA-256 hash; write doc with 5-min expiry, attempts reset,
     `verified: false`, new `resendAvailableAt`.
  5. Send via Nodemailer + Gmail (`user`: project mailbox, `pass`: Functions
     config `gmail.pass`). Subject: "Your Ferrer verification code".
  6. Return generic success (`{sent: true}`) regardless of prior state to
     avoid account enumeration. Log only hashes, never codes.
- `verifyEmailOtp({email, code})`
  1. Normalize email; fetch doc; if missing/expired/attempts >= 5, delete or
     invalidate and return `expired` / `too-many-attempts`.
  2. Hash incoming code with stored salt; constant-time compare.
  3. Wrong: increment `attempts`; if now >= 5, invalidate doc.
  4. Right: set `verified: true`, delete `codeHash`/`salt`, return
     `{verified: true, verificationToken}` where the token is a short-lived
     signed receipt (e.g. HMAC of email + timestamp with a Functions-side
     secret, 10-min TTL) that `signUp` enforcement can check — or simplest
     v1: the app proceeds to `signUp()` and a Firestore check is skipped
     because only a verified client reaches that step (documented tradeoff;
     v2 can enforce token server-side in a `beforeCreate` blocking function).

Config (never committed):
`firebase functions:config:set gmail.user="..." gmail.pass="..." otp.hmac_secret="..."`
(or `.env` gitignored for the emulator). App password obtained from Google
Account with 2-Step Verification enabled.

## 5. Client Changes (Flutter)

- `AuthDataSource` += `requestEmailOtp(email)`, `verifyEmailOtp(email, code)`.
  - Firebase impl calls the HTTPS endpoints, maps errors to `Failure`.
  - Mock impl: `requestEmailOtp` no-op success; `verifyEmailOtp` accepts
    `123456`, rejects others — keeps offline demo working.
- `AuthRepository` += same two methods with friendly error mapping.
- `AuthViewModel` += `otpState` (idle/sending/codeSent/verifying/verified),
  `resendCooldownSeconds`, `otpError`; clears error on retry/resend.
- Signup UI becomes 2 steps in the existing bottom sheet (no new route):
  Step 1 (name/email/phone/password) → auto-request → Step 2 six-box code
  entry with paste support, 60s resend countdown, attempt-aware messages
  ("3 attempts left", "Code expired — resend a new one").
- Login screen untouched.
- All new sheets follow the repo's keyboard-safe pattern
  (`isScrollControlled` + `viewInsets.bottom` padding + scrollable content).

## 6. Error Handling (user-facing copy)

| Case                    | Message                                              |
|-------------------------|------------------------------------------------------|
| Invalid email           | Existing `Validators.email` message.                 |
| Resend too soon         | "Wait {n}s before requesting a new code."            |
| Wrong code              | "Incorrect code. {n} attempt(s) left."               |
| Attempts exhausted      | "Too many attempts. Request a new code."             |
| Expired                 | "Code expired. Send a new one."                      |
| Network / unknown       | "Could not verify. Check your connection and retry." |

No stack traces or raw codes in UI or logs.

## 7. Testing

- Unit: code-doc lifecycle (expiry, attempts cap, cooldown) via Functions
  emulator tests or pure helper tests for hash/compare/throttle logic;
  `AuthViewModel` otpState transitions; mock datasource `123456` accept.
- Widget (optional): 6-box entry + resend timer states.
- Manual: real Gmail send, expired-code path, resend-cooldown path,
  offline mock path with `123456`.
- `flutter analyze` clean; full `flutter test` green before merge.

## 8. Rollout / Risks

- Deploy Functions first, then client (client degrades to "service
  unavailable, try again" if endpoints missing).
- Gmail caps (~500/day) and spam-folder risk accepted for school scope;
  Resend driver swap documented as follow-up (only the send call changes).
- Old accounts unaffected; no migration.
