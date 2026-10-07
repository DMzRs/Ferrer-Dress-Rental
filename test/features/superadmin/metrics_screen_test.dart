import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/admin/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/reports/presentation/viewmodels/reports_viewmodel.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/views/metrics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Rental _completedRental() => Rental(
      id: 'r1',
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Gown',
      startDate: DateTime(2026, 9, 18),
      endDate: DateTime(2026, 9, 20),
      rentalFee: 2000,
      securityDeposit: 500,
      total: 2500,
      status: 'completed',
      createdAt: DateTime(2026, 9, 17),
      returnedAt: DateTime(2026, 9, 21),
    );

class _MetricsRentalRepository implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream<List<Rental>>.value(const []);

  @override
  Stream<List<Rental>> allRentalsStream() =>
      Stream<List<Rental>>.value([_completedRental()]);

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

class _MetricsAuthRepository implements AuthRepository {
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
  Stream<int> usersCountStream() => Stream<int>.value(0);

  @override
  Stream<List<AppUser>> watchUsers() => Stream<List<AppUser>>.value([]);
}

void main() {
  testWidgets('revenue card shows developer share beside total revenue',
      (t) async {
    final rentals = _MetricsRentalRepository();
    final inventory = _EmptyInventoryRepository();
    final appointments = _EmptyAppointmentRepository();
    final auth = _MetricsAuthRepository();
    t.view.physicalSize = const Size(1200, 800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: auth),
          ChangeNotifierProvider<AuthViewModel>(
            create: (_) => AuthViewModel(auth),
          ),
          ChangeNotifierProvider<DashboardViewModel>(
            create: (_) => DashboardViewModel(
              rentalRepository: rentals,
              inventoryRepository: inventory,
              appointmentRepository: appointments,
              authRepository: auth,
            ),
          ),
          ChangeNotifierProvider<ReportsViewModel>(
            create: (_) => ReportsViewModel(rentals),
          ),
        ],
        child: const MaterialApp(home: MetricsScreen()),
      ),
    );
    await t.pumpAndSettle();
    // ₱2,000 revenue → 5% developer share is ₱100.
    expect(find.text('₱2,000'), findsOneWidget);
    expect(find.textContaining('DEVELOPER SHARE'), findsOneWidget);
    expect(find.text('₱100'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
