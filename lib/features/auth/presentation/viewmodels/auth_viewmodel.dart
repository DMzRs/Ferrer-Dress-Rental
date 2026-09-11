import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum EmailLinkState { idle, sending, linkSent, verifying, verified }

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

  EmailLinkState _linkState = EmailLinkState.idle;
  String? _linkError;
  int _resendCooldownSeconds = 0;
  Timer? _cooldownTimer;
  StreamSubscription<String>? _linkSub;
  bool _disposed = false;

  // Step-1 signup details, kept so an incoming link can complete the flow.
  String _linkName = '';
  String _linkEmail = '';
  String _linkPhone = '';
  String _linkPassword = '';

  AppUser? get user => _user;
  bool get busy => _busy;
  String? get error => _error;

  EmailLinkState get linkState => _linkState;
  String? get linkError => _linkError;
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

  /// Signup step 1: sends the email sign-in link and starts listening for
  /// the incoming app link so tapping it completes signup automatically.
  Future<bool> sendLink({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _linkError = null;
    _linkState = EmailLinkState.sending;
    notifyListeners();
    final result = await _repository.sendSignInLink(email);
    if (_disposed) return result is Success;
    if (result is Success) {
      _linkName = fullName.trim();
      _linkEmail = email.trim();
      _linkPhone = phone.trim();
      _linkPassword = password;
      _linkState = EmailLinkState.linkSent;
      _startCooldown();
      _listenForLink();
    } else {
      _linkState = EmailLinkState.idle;
      _linkError =
          result.failure?.message ?? 'Something went wrong. Please try again.';
    }
    notifyListeners();
    return result is Success;
  }

  /// Signup step 2: completes sign-in with a tapped (or demo) link, attaches
  /// the password login, and creates the profile.
  Future<bool> completeWithLink(String link) async {
    _linkError = null;
    _linkState = EmailLinkState.verifying;
    notifyListeners();
    final result = await _repository.signInWithEmailLink(
      email: _linkEmail,
      link: link,
      fullName: _linkName,
      phone: _linkPhone,
      password: _linkPassword,
    );
    if (_disposed) return result is Success;
    if (result is Success<AppUser>) {
      _user = result.data;
      _linkState = EmailLinkState.verified;
    } else {
      _linkState = EmailLinkState.linkSent;
      _linkError =
          result.failure?.message ?? 'Something went wrong. Please try again.';
    }
    notifyListeners();
    return result is Success;
  }

  void _listenForLink() {
    _linkSub?.cancel();
    _linkSub = _repository.emailLinkStream().listen((link) async {
      if (_disposed || _linkState != EmailLinkState.linkSent) return;
      await completeWithLink(link);
    });
  }

  void resetLink() {
    _linkSub?.cancel();
    _linkSub = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _linkState = EmailLinkState.idle;
    _linkError = null;
    _resendCooldownSeconds = 0;
    _linkName = '';
    _linkEmail = '';
    _linkPhone = '';
    _linkPassword = '';
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
    _linkSub?.cancel();
    _linkSub = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _subscription?.cancel();
    super.dispose();
  }
}
