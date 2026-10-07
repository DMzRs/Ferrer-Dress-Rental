import 'dart:async';

import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/audit/domain/audit_logger.dart';
import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';
import 'package:ferrer_rental_shop/features/audit/domain/repositories/audit_repository.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _admin = AppUser(
  uid: 'admin-1',
  fullName: 'Shop Staff',
  email: 'admin@ferrer.ph',
  phone: '',
  role: UserRole.admin,
);

class _FakeAuditRepository implements AuditRepository {
  final entries = <AuditLogEntry>[];

  @override
  Stream<List<AuditLogEntry>> watchLogs({int limit = 100}) =>
      Stream.value(List.unmodifiable(entries));

  @override
  Future<void> log(AuditLogEntry entry) async {
    entries.add(entry);
  }
}

class _FakeAuthForAudit implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  void emit(AppUser? user) => _controller.add(user);

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<Result<AppUser>> signIn(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signUp(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendSignInLink(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signInWithEmailLink(
          {required String email,
          required String link,
          String? fullName,
          String? phone,
          String? password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<Result<AppUser>> linkGoogleAccount(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> createAdmin(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> updateUserRole(
          {required String uid, required UserRole role}) =>
      throw UnimplementedError();

  @override
  Stream<String> emailLinkStream() => Stream<String>.empty();

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<void>> updateProfile(
          {String? fullName,
          String? phone,
          String? address,
          List<String>? savedPlaces}) =>
      throw UnimplementedError();

  @override
  Stream<int> usersCountStream() => Stream<int>.empty();

  @override
  Stream<List<AppUser>> watchUsers() => Stream<List<AppUser>>.value([]);
}

void main() {
  test('logs with the signed-in actor', () async {
    final auth = _FakeAuthForAudit();
    final audit = _FakeAuditRepository();
    final logger = AuditLogger(auth: auth, logs: audit);
    addTearDown(logger.dispose);
    auth.emit(_admin);
    await Future<void>.delayed(Duration.zero);
    await logger.log('rental.confirmed', targetId: 'r1');
    expect(audit.entries, hasLength(1));
    expect(audit.entries.single.actorUid, 'admin-1');
    expect(audit.entries.single.action, 'rental.confirmed');
    expect(audit.entries.single.targetId, 'r1');
  });

  test('explicit actor overrides the stream user', () async {
    final auth = _FakeAuthForAudit();
    final audit = _FakeAuditRepository();
    final logger = AuditLogger(auth: auth, logs: audit);
    addTearDown(logger.dispose);
    const other = AppUser(
      uid: 'u9',
      fullName: 'Newbie',
      email: 'n@x.com',
      phone: '',
      role: UserRole.customer,
    );
    await logger.log('user.signup', actor: other);
    expect(audit.entries.single.actorUid, 'u9');
  });

  test('no actor means no-op, never throws', () async {
    final auth = _FakeAuthForAudit();
    final audit = _FakeAuditRepository();
    final logger = AuditLogger(auth: auth, logs: audit);
    addTearDown(logger.dispose);
    await logger.log('rental.confirmed', targetId: 'r1');
    expect(audit.entries, isEmpty);
  });
}
