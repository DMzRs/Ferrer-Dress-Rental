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
  const d = snap.data() || {};
  const resendAt = d.resendAvailableAt && d.resendAvailableAt.toMillis ? d.resendAvailableAt.toMillis() : 0;
  if (snap.exists && !otp.canResend(resendAt, now)) {
    const retry = Math.ceil((resendAt - now) / 1000);
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
