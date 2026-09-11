import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum OtpState { idle, sending, codeSent, verifying, verified }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository) {
    _subscription = _repository.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _subscription;

  AppUser? _user;
  bool _busy = false;
  String? _error;

  OtpState _otpState = OtpState.idle;
  String? _otpError;
  int _resendCooldownSeconds = 0;
  Timer? _cooldownTimer;
  bool _disposed = false;

  AppUser? get user => _user;
  bool get busy => _busy;
  String? get error => _error;

  OtpState get otpState => _otpState;
  String? get otpError => _otpError;
  int get resendCooldownSeconds => _resendCooldownSeconds;

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    return _run(() => _repository.signIn(email: email.trim(), password: password));
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _error = null;
    _setBusy(true);
    final result = await _repository.signUp(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
    _setBusy(false);
    if (result is Success<AppUser>) {
      // The auth stream can emit a raced snapshot mid-sign-up (before the
      // profile doc write lands); trust this result instead.
      _user = result.data;
      notifyListeners();
      return true;
    }
    _error = result.failure?.message ?? 'Something went wrong. Please try again.';
    notifyListeners();
    return false;
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _repository.sendPasswordReset(email.trim()));
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    List<String>? savedPlaces,
  }) async {
    final ok = await _run(() => _repository.updateProfile(
          fullName: fullName,
          phone: phone,
          address: address,
          savedPlaces: savedPlaces,
        ));
    if (ok) {
      _user = _user?.copyWith(
        fullName: fullName?.trim(),
        phone: phone?.trim(),
        address: address?.trim(),
        savedPlaces: savedPlaces,
      );
      notifyListeners();
    }
    return ok;
  }

  Future<bool> _run(Future<Result<dynamic>> Function() action) async {
    _error = null;
    _setBusy(true);
    final result = await action();
    if (result is Success) {
      _setBusy(false);
      return true;
    }
    _setBusy(false);
    _error = result.failure?.message ?? 'Something went wrong. Please try again.';
    notifyListeners();
    return false;
  }

  Future<void> signOut() => _repository.signOut();

  Future<bool> sendOtp(String email) async {
    _otpError = null;
    _otpState = OtpState.sending;
    notifyListeners();
    final result = await _repository.requestEmailOtp(email);
    if (_disposed) return result is Success;
    if (result is Success) {
      _otpState = OtpState.codeSent;
      _startCooldown();
    } else {
      _otpState = OtpState.idle;
      _otpError =
          result.failure?.message ?? 'Something went wrong. Please try again.';
    }
    notifyListeners();
    return result is Success;
  }

  Future<bool> confirmOtp({required String email, required String code}) async {
    _otpError = null;
    _otpState = OtpState.verifying;
    notifyListeners();
    final result = await _repository.verifyEmailOtp(email: email, code: code);
    if (_disposed) return result is Success;
    if (result is Success) {
      _otpState = OtpState.verified;
    } else {
      _otpState = OtpState.codeSent;
      _otpError =
          result.failure?.message ?? 'Something went wrong. Please try again.';
    }
    notifyListeners();
    return result is Success;
  }

  void resetOtp() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _otpState = OtpState.idle;
    _otpError = null;
    _resendCooldownSeconds = 0;
    if (!_disposed) notifyListeners();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _resendCooldownSeconds = 60;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (_resendCooldownSeconds <= 0) {
        timer.cancel();
        return;
      }
      _resendCooldownSeconds--;
      notifyListeners();
      if (_resendCooldownSeconds <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _subscription?.cancel();
    super.dispose();
  }
}
