# Email OTP Client Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Two-step signup in the app: details → 6-digit code entry → account created.

**Architecture:** New `requestEmailOtp`/`verifyEmailOtp` methods threaded through data source → repository → viewmodel, consumed by a Step-2 sheet UI; `cloud_functions` calls the deployed backend from the backend plan.

**Tech Stack:** Flutter, `cloud_functions` package, provider (existing `AuthViewModel`).

**Spec:** `docs/superpowers/specs/2026-09-11-email-otp-design.md`. Backend endpoints: `docs/superpowers/plans/2026-09-11-email-otp-backend.md`.

## Global Constraints

- Login screen untouched.
- Mock data source accepts code `123456`, rejects others — offline demo keeps working.
- New sheets follow repo keyboard-safe pattern (`isScrollControlled` + `viewInsets.bottom` + scrollable).
- `flutter analyze` clean and full `flutter test` green before merge.

---

### Task 1: Dependency + data layer

**Files:**
- Modify: `pubspec.yaml` (add `cloud_functions: ^5.1.0`)
- Modify: `lib/features/auth/data/datasources/auth_data_source.dart` (add 2 signatures)
- Modify: `lib/features/auth/data/datasources/firebase_auth_data_source.dart` (implement via `FirebaseFunctions`)
- Modify: `lib/features/auth/data/datasources/mock_auth_data_source.dart` (fixed `123456`)
- Modify: `lib/features/auth/domain/repositories/auth_repository.dart` (add 2 signatures)
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart` (delegate + friendly errors)
- Test: extend `test/features/auth/` fakes (exact file found by executor via glob)

**Interfaces:**
- Consumes: deployed `requestEmailOtp`, `verifyEmailOtp` callables.
- Produces (exact signatures for Task 2):
  - `Future<void> requestEmailOtp(String email)`
  - `Future<void> verifyEmailOtp({required String email, required String code})` (throws `Failure` with user-facing message)

- [ ] **Step 1: Write the failing test** — in the auth repository/viewmodel test file, add:

```dart
test('verifyEmailOtp accepts 123456 in mock mode', () async {
  final ds = MockAuthDataSource();
  await ds.requestEmailOtp('j@x.com');
  await ds.verifyEmailOtp(email: 'j@x.com', code: '123456');
});
```

(Executor: adapt class/constructor names to the real `MockAuthDataSource` found in-repo; the two method names above are normative.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/`
Expected: FAIL with `NoSuchMethodError` (methods do not exist yet).

- [ ] **Step 3: Write minimal implementation**
  - `pubspec.yaml`: add `cloud_functions: ^5.1.0`, run `flutter pub get`.
  - Firebase impl:

```dart
import 'package:cloud_functions/cloud_functions.dart';

@override
Future<void> requestEmailOtp(String email) async {
  try {
    await FirebaseFunctions.instance.httpsCallable('requestEmailOtp').call({'email': email.trim()});
  } on FirebaseFunctionsException catch (e) {
    throw Exception(e.message ?? 'Could not send the code.');
  }
}

@override
Future<void> verifyEmailOtp({required String email, required String code}) async {
  try {
    await FirebaseFunctions.instance.httpsCallable('verifyEmailOtp').call({'email': email.trim(), 'code': code.trim()});
  } on FirebaseFunctionsException catch (e) {
    throw Exception(e.message ?? 'Could not verify the code.');
  }
}
```

  - Mock impl: `requestEmailOtp` returns after 500ms; `verifyEmailOtp` throws `Exception('Incorrect code. Try 123456 in demo mode.')` unless code is `123456`.
  - Repository impl delegates; maps any exception message through unchanged.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/features/auth/
git commit -m "feat(otp): email OTP data layer with mock 123456"
```

---

### Task 2: ViewModel OTP state

**Files:**
- Modify: `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`
- Test: auth viewmodel test file

**Interfaces:**
- Consumes: Task 1 repository methods.
- Produces (exact API for Task 3):
  - `OtpState { idle, sending, codeSent, verifying, verified }`, `vm.otpState`
  - `String? vm.otpError`, `int vm.resendCooldownSeconds`
  - `Future<bool> vm.sendOtp(String email)`, `Future<bool> vm.confirmOtp({required String email, required String code})`, `void vm.resetOtp()`

- [ ] **Step 1: Write the failing test**

```dart
test('sendOtp transitions idle->sending->codeSent', () async {
  final vm = AuthViewModel(fakeRepository);
  expect(vm.otpState, OtpState.idle);
  final ok = await vm.sendOtp('j@x.com');
  expect(ok, isTrue);
  expect(vm.otpState, OtpState.codeSent);
});
```

(Executor: match the real `AuthViewModel` constructor; add the `OtpState` enum in the viewmodel file.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/`
Expected: FAIL (`OtpState` undefined).

- [ ] **Step 3: Write minimal implementation** — enum + fields + methods; `sendOtp` sets `sending`, calls repo, on success `codeSent` + starts 60s cooldown timer (single `Timer`, cancelled in `dispose`); `confirmOtp` sets `verifying`, on success `verified`; both set `otpError` from caught message and clear it on each new attempt; `resetOtp` restores idle.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/viewmodels/auth_viewmodel.dart
git commit -m "feat(otp): viewmodel OTP state machine with resend cooldown"
```

---

### Task 3: Two-step signup UI

**Files:**
- Modify: signup sheet in `lib/features/auth/presentation/views/login_screen.dart` (executor: locate the signup bottom sheet via grep for `signUp`)
- Test: manual + existing suite (no new automated test required; sheet is thin over Task 2 state)

**Interfaces:**
- Consumes: Task 2 `otpState`, `otpError`, `resendCooldownSeconds`, `sendOtp`, `confirmOtp`, `resetOtp`.

- [ ] **Step 1: Reorganize signup sheet into Step 1 (details) and Step 2 (code)**
  - After existing Step-1 validation passes, call `vm.sendOtp(email)`; on true, flip local `otpStep = true` (keep entered details in local vars).
  - Step 2 shows: six single-char `TextField`s in a `Row` (numeric keyboard, auto-advance focus, backspace moves back, full-code paste fills all six), resend row (`Resend in {n}s` countdown or `Resend code` button calling `sendOtp` again), error text from `vm.otpError`, Verify button bound to `vm.confirmOtp(email: savedEmail, code: joined)`.
  - On verified: call existing `signUp(...)` with saved details, then `vm.resetOtp()`, close sheet.
  - Sheet keeps `isScrollControlled: true` + `Padding(bottom: viewInsets.bottom)` + `SingleChildScrollView`.

- [ ] **Step 2: Run manual check** — emulator offline (mock): enter any signup details, code `123456` succeeds; `000000` shows the incorrect-code message; resend button counts down from 60.

- [ ] **Step 3: Run automated suite**

Run: `flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`.

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/presentation/views/login_screen.dart
git commit -m "feat(otp): two-step signup with 6-digit code entry"
```

---

### Task 4: End-to-end verification (backend deployed)

**Files:** none (verification only).

- [ ] **Step 1: Point app at real backend** — run on a device/emulator with network (Firebase mode, not mock).
- [ ] **Step 2: Signup with a real inbox** — receive code within ~30s; wrong code shows attempts-left; wait 5 min, code expires; resend respects 60s cooldown.
- [ ] **Step 3: Confirm no secret leakage** — `git status --short` clean of `.env`; `git check-ignore functions/.env` returns the ignore rule; no codes in logcat/Functions logs (hashes only).
- [ ] **Step 4: Final full run** — `flutter analyze` + `flutter test` green, then push per repo habit (one commit per task already done above).
