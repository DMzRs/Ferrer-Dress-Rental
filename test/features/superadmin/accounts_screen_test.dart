import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/audit/data/datasources/mock_audit_data_source.dart';
import 'package:ferrer_rental_shop/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:ferrer_rental_shop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/audit/data/repositories/audit_repository_impl.dart';
import 'package:ferrer_rental_shop/features/audit/domain/audit_logger.dart';
import 'package:ferrer_rental_shop/features/audit/domain/repositories/audit_repository.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/viewmodels/accounts_viewmodel.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/viewmodels/audit_log_viewmodel.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/views/accounts_screen.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/views/logs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FailingDirectoryAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(null);

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
  Stream<List<AppUser>> watchUsers() =>
      Stream<List<AppUser>>.error(Exception('permission-denied'));
}

void main() {
  testWidgets('denied directory shows an error, not an empty state',
      (t) async {
    final auth = _FailingDirectoryAuthRepository();
    final auditRepo = AuditRepositoryImpl(MockAuditDataSource());
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: auth),
          Provider<AuditRepository>.value(value: auditRepo),
          Provider<AuditLogger>(
            create: (_) => AuditLogger(auth: auth, logs: auditRepo),
          ),
          ChangeNotifierProvider<AuthViewModel>(
            create: (_) => AuthViewModel(auth),
          ),
          ChangeNotifierProvider<AccountsViewModel>(
            create: (c) => AccountsViewModel(
              auth: c.read<AuthRepository>(),
              audit: c.read<AuditLogger>(),
            ),
          ),
        ],
        child: const MaterialApp(home: AccountsScreen()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('No accounts yet'), findsNothing);
    expect(find.text('Couldn\'t load accounts'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('denied log feed shows an error, not an empty state',
      (t) async {
    final auth = _FailingDirectoryAuthRepository();
    final auditRepo = _FailingLogRepository();
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: auth),
          Provider<AuditRepository>.value(value: auditRepo),
          Provider<AuditLogger>(
            create: (_) => AuditLogger(auth: auth, logs: auditRepo),
          ),
          ChangeNotifierProvider<AuthViewModel>(
            create: (_) => AuthViewModel(auth),
          ),
          ChangeNotifierProvider<AuditLogViewModel>(
            create: (c) =>
                AuditLogViewModel(c.read<AuditRepository>()),
          ),
        ],
        child: const MaterialApp(home: LogsScreen()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('No activity yet'), findsNothing);
    expect(find.text('Couldn\'t load logs'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('backfilled tiles name the subject, not just the importer',
      (t) async {
    final auth = _FailingDirectoryAuthRepository();
    final auditRepo = _SeededLogRepository();
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: auth),
          Provider<AuditRepository>.value(value: auditRepo),
          Provider<AuditLogger>(
            create: (_) => AuditLogger(auth: auth, logs: auditRepo),
          ),
          ChangeNotifierProvider<AuthViewModel>(
            create: (_) => AuthViewModel(auth),
          ),
          ChangeNotifierProvider<AuditLogViewModel>(
            create: (c) =>
                AuditLogViewModel(c.read<AuditRepository>()),
          ),
        ],
        child: const MaterialApp(home: LogsScreen()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('maria@example.com'), findsWidgets);
    expect(find.textContaining('imported'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('demoting a dues-free admin still asks for confirmation',
      (t) async {
    final auth = AuthRepositoryImpl(MockAuthDataSource());
    final auditRepo = AuditRepositoryImpl(MockAuditDataSource());
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: auth),
          Provider<AuditRepository>.value(value: auditRepo),
          Provider<AuditLogger>(
            create: (c) => AuditLogger(
              auth: c.read<AuthRepository>(),
              logs: c.read<AuditRepository>(),
            ),
          ),
          ChangeNotifierProvider<AuthViewModel>(
            create: (c) => AuthViewModel(c.read<AuthRepository>()),
          ),
          ChangeNotifierProvider<AccountsViewModel>(
            create: (c) => AccountsViewModel(
              auth: c.read<AuthRepository>(),
              audit: c.read<AuditLogger>(),
              rentals: _EmptyRentals(),
            ),
          ),
        ],
        child: const MaterialApp(home: AccountsScreen()),
      ),
    );
    await t.pumpAndSettle();
    // Open the admin row's role menu (admin@ferrer.ph is the seeded admin).
    await t.tap(find
        .byWidgetPredicate((w) =>
            w is PopupMenuButton<UserRole> &&
            find.descendant(of: find.byWidget(w), matching: find.text('Admin')).evaluate().isNotEmpty)
        .first);
    await t.pumpAndSettle();
    await t.tap(find.text('Demote to customer').last);
    await t.pumpAndSettle();
    expect(find.text('Demote Anyway'), findsOneWidget);
    expect(find.text('Keep Admin'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}

class _EmptyRentals implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream<List<Rental>>.value(const []);

  @override
  Stream<List<Rental>> allRentalsStream() =>
      Stream<List<Rental>>.value(const []);

  @override
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) =>
      Stream<List<Rental>>.value(const []);

  @override
  Future<String> createRental(Rental rental) async => 'new-id';

  @override
  Future<void> completeRental(String id, {DateTime? returnedAt}) async {}

  @override
  Future<void> cancelRental(String id) async {}

  @override
  Future<void> updateRentalStatus(String id, String status,
          {String? declineReason}) async {}
}

class _SeededLogRepository implements AuditRepository {
  @override
  Stream<List<AuditLogEntry>> watchLogs({int limit = 100}) =>
      Stream<List<AuditLogEntry>>.value([
        AuditLogEntry(
          id: 'log-1',
          actorUid: 'superadmin-001',
          actorEmail: 'owner@ferrer.ph',
          action: 'user.signup',
          targetType: 'user',
          targetId: 'user-001',
          at: DateTime(2026, 9, 1),
          meta: const {
            'backfilled': 'true',
            'email': 'maria@example.com',
            'role': 'customer',
          },
        ),
      ]);

  @override
  Future<void> log(AuditLogEntry entry) async {}
}

class _FailingLogRepository implements AuditRepository {
  @override
  Stream<List<AuditLogEntry>> watchLogs({int limit = 100}) async* {
    await Future<void>.delayed(Duration.zero);
    throw Exception('permission-denied');
  }

  @override
  Future<void> log(AuditLogEntry entry) async {}
}
