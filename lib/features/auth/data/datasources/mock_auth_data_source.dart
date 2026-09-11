import 'dart:async';

import 'package:ferrer_rental_shop/features/auth/data/models/app_user_model.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';

import 'auth_data_source.dart';

class MockAuthDataSource implements AuthDataSource {
  MockAuthDataSource() {
    _users.addAll([
      const AppUserModel(
        uid: 'admin-001',
        fullName: 'Ms. Ferrer',
        email: 'admin@ferrer.ph',
        phone: '09171234567',
        role: UserRole.admin,
      ),
      const AppUserModel(
        uid: 'user-001',
        fullName: 'Maria Santos',
        email: 'maria@example.com',
        phone: '09981234567',
        role: UserRole.customer,
      ),
    ]);
  }

  final List<AppUserModel> _users = [];
  final StreamController<AppUserModel?> _session = StreamController.broadcast();
  AppUserModel? _current;

  static const String _demoPassword = 'ferrer123';

  void _setSession(AppUserModel? user) {
    _current = user;
    if (!_session.isClosed) _session.add(user);
  }

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield _current;
    await for (final user in _session.stream) {
      yield user;
    }
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final normalized = email.trim().toLowerCase();
    final match = _users.where((u) => u.email.toLowerCase() == normalized).toList();
    if (match.isEmpty) {
      throw Exception('No account found for this email.');
    }
    final user = match.first;
    final isKnownDemo =
        user.email == 'admin@ferrer.ph' || user.email == 'maria@example.com';
    if (isKnownDemo && password != _demoPassword) {
      throw Exception('Incorrect password. Demo password: $_demoPassword');
    }
    if (!isKnownDemo && password.length < 6) {
      throw Exception('Incorrect password.');
    }
    _setSession(user);
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final normalized = email.trim().toLowerCase();
    if (_users.any((u) => u.email.toLowerCase() == normalized)) {
      throw Exception('An account with this email already exists.');
    }
    final user = AppUserModel(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: normalized,
      phone: phone.trim(),
      role: UserRole.customer,
    );
    _users.add(user);
    _setSession(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final normalized = email.trim().toLowerCase();
    if (!_users.any((u) => u.email.toLowerCase() == normalized)) {
      throw Exception('No account found for this email.');
    }
  }

  @override
  Future<void> requestEmailOtp(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> verifyEmailOtp({required String email, required String code}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (code.trim() != '123456') {
      throw Exception('Incorrect code. Try 123456 in demo mode.');
    }
  }

  @override
  Future<void> signOut() async {
    _setSession(null);
  }

  @override
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    List<String>? savedPlaces,
  }) async {
    final current = _current;
    if (current == null) throw Exception('Not signed in');
    final updated = AppUserModel(
      uid: current.uid,
      fullName: fullName?.trim() ?? current.fullName,
      email: current.email,
      phone: phone?.trim() ?? current.phone,
      address: address?.trim() ?? current.address,
      savedPlaces: savedPlaces ?? current.savedPlaces,
      role: current.role,
    );
    final index = _users.indexWhere((u) => u.uid == current.uid);
    if (index != -1) _users[index] = updated;
    _setSession(updated);
  }

  @override
  Stream<int> usersCountStream() {
    late StreamController<int> controller;
    late Timer timer;
    controller = StreamController(
      onListen: () {
        void emit() {
          if (!controller.isClosed) controller.add(_users.length);
        }

        emit();
        timer = Timer.periodic(const Duration(seconds: 3), (_) => emit());
      },
      onCancel: () => timer.cancel(),
    );
    return controller.stream;
  }

  AppUserModel? get currentUser => _current;
}
