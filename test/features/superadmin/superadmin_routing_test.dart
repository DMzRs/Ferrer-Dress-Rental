import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/core/widgets/auth_gate.dart';
import 'package:ferrer_rental_shop/features/audit/data/datasources/mock_audit_data_source.dart';
import 'package:ferrer_rental_shop/features/audit/data/repositories/audit_repository_impl.dart';
import 'package:ferrer_rental_shop/features/audit/domain/audit_logger.dart';
import 'package:ferrer_rental_shop/features/audit/domain/repositories/audit_repository.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/views/super_admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _GateAuthRepository implements AuthRepository {
  _GateAuthRepository(this.user);

  final AppUser? user;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(user);

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

class _EmptyRentalRepository implements RentalRepository {
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

class _EmptyInventoryRepository implements InventoryRepository {
  @override
  Stream<List<CatalogItem>> itemsStream() =>
      Stream<List<CatalogItem>>.value(const []);

  @override
  Future<String> addItem(CatalogItem item) async => 'x';

  @override
  Future<void> updateItem(CatalogItem item) async {}

  @override
  Future<void> updateStatus(String itemId, String status) async {}

  @override
  Future<void> saveItemPhotos(String itemId, List<String> photos) async {}

  @override
  Future<List<String>> itemPhotos(String itemId) async => [];
}

class _EmptyAppointmentRepository implements AppointmentRepository {
  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) =>
      Stream<List<Appointment>>.value(const []);

  @override
  Stream<List<Appointment>> allAppointmentsStream() =>
      Stream<List<Appointment>>.value(const []);

  @override
  Stream<List<Appointment>> pagedAppointmentsStream({int limit = 20}) =>
      Stream<List<Appointment>>.value(const []);

  @override
  Future<List<String>> bookedSlotsFor(DateTime day) async => [];

  @override
  Future<void> createAppointment(Appointment appointment) async {}

  @override
  Future<void> cancelAppointment(String id) async {}

  @override
  Future<void> updateStatus(String id, String status,
          {String? declineReason}) async {}
}

Future<void> _pumpGate(WidgetTester t, AppUser? user) async {
  final auth = _GateAuthRepository(user);
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
        Provider<RentalRepository>.value(value: _EmptyRentalRepository()),
        Provider<InventoryRepository>.value(
            value: _EmptyInventoryRepository()),
        Provider<AppointmentRepository>.value(
            value: _EmptyAppointmentRepository()),
      ],
      child: MaterialApp(
        home: Builder(builder: (context) {
          return AuthGate(authRepository: context.read<AuthRepository>());
        }),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  const owner = AppUser(
    uid: 'superadmin-001',
    fullName: 'Shop Owner',
    email: 'owner@ferrer.ph',
    phone: '',
    role: UserRole.superadmin,
  );

  testWidgets('superadmin lands on the superadmin shell', (t) async {
    await _pumpGate(t, owner);
    expect(find.byType(SuperAdminShell), findsOneWidget);
    expect(find.text('Accounts'), findsWidgets);
    expect(find.text('Metrics'), findsWidgets);
    expect(find.text('Logs'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
