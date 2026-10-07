import 'dart:async';

import 'package:ferrer_rental_shop/features/auth/data/models/app_user_model.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';

import 'auth_data_source.dart';

/// In-memory demo users with session broadcast.
class MockAuthDataSource implements AuthDataSource {
  MockAuthDataSource() {
    _users.addAll([
      const AppUserModel(
        uid: 'superadmin-001',
        fullName: 'Shop Owner',
        email: 'owner@ferrer.ph',
        phone: '09171234567',
        role: UserRole.superadmin,
      ),
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

  /// Emits current user then session updates.
  @override
  Stream<AppUser?> get authStateChanges async* {
    yield _current;
    await for (final user in _session.stream) {
      yield user;
    }
  }

  /// Signs in demo user by email and password.
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

  /// Registers customer and starts session.
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

  /// Simulates password-reset email lookup.
  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final normalized = email.trim().toLowerCase();
    if (!_users.any((u) => u.email.toLowerCase() == normalized)) {
      throw Exception('No account found for this email.');
    }
  }

  /// Simulates sending email sign-in link.
  @override
  Future<void> sendSignInLink(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Throws since mock has no Google chooser.
  @override
  Future<AppUser> signInWithGoogle() {
    // Mock mode has no Google account chooser; the login UI hides the
    // Google button when Firebase is off.
    throw UnimplementedError('Google sign-in needs Firebase.');
  }

  /// Throws since mock has no Google linking.
  @override
  Future<AppUser> linkGoogleAccount({
    required String email,
    required String password,
  }) {
    throw UnimplementedError('Google sign-in needs Firebase.');
  }

  /// Signs in or registers via email link.
  @override
  Future<AppUser> signInWithEmailLink({
    required String email,
    required String link,
    String? fullName,
    String? phone,
    String? password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Demo mode: any link tap counts as proof of inbox ownership.
    final normalized = email.trim().toLowerCase();
    final match = _users.where((u) => u.email.toLowerCase() == normalized).toList();
    if (match.isNotEmpty) {
      _setSession(match.first);
      return match.first;
    }
    final user = AppUserModel(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: (fullName ?? '').trim(),
      email: normalized,
      phone: (phone ?? '').trim(),
      role: UserRole.customer,
    );
    _users.add(user);
    _setSession(user);
    return user;
  }

  /// Empty stream since mock has no deep links.
  @override
  Stream<String> get emailLinkStream => const Stream.empty();

  /// Clears current session.
  @override
  Future<void> signOut() async {
    _setSession(null);
  }

  /// Updates signed-in user fields in memory.
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

  /// Polls in-memory user count every 3 seconds.
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

  /// Streams user list on session changes.
  @override
  Stream<List<AppUser>> watchUsers() async* {
    yield List.unmodifiable(_users);
    await for (final _ in _session.stream) {
      yield List.unmodifiable(_users);
    }
  }

  /// Adds new admin without changing session.
  @override
  Future<AppUser> createAdmin({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final normalized = email.trim().toLowerCase();
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    if (_users.any((u) => u.email.toLowerCase() == normalized)) {
      throw Exception('An account with this email already exists.');
    }
    final user = AppUserModel(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: normalized,
      phone: phone.trim(),
      role: UserRole.admin,
    );
    _users.add(user);
    // Tick watchers (accounts list) without touching the session: only
    // re-emit when someone is signed in, so this never signs anyone out.
    if (_current != null) _setSession(_current);
    return user;
  }

  /// Changes user role with demotion guards.
  @override
  Future<AppUser> updateUserRole({
    required String uid,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index == -1) throw Exception('Account not found.');
    final current = _users[index];
    if (current.role == UserRole.superadmin && role != UserRole.superadmin) {
      throw Exception('A superadmin account cannot be demoted.');
    }
    if (current.role == UserRole.customer && role == UserRole.admin) {
      throw Exception(
          'Admin accounts must be created fresh via Register Admin.');
    }
    final updated = AppUserModel(
      uid: current.uid,
      fullName: current.fullName,
      email: current.email,
      phone: current.phone,
      address: current.address,
      savedPlaces: current.savedPlaces,
      role: role,
    );
    _users[index] = updated;
    // Refresh watchers (and a viewer looking at their own row) without
    // ever emitting null — emitting null would sign the viewer out.
    final viewer = _current;
    if (viewer != null) {
      _setSession(viewer.uid == uid ? updated : viewer);
    }
    return updated;
  }

  /// Currently signed-in mock user.
  AppUserModel? get currentUser => _current;
}
