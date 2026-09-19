import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/shell/presentation/views/user_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _user = AppUser(
    uid: 'u1',
    fullName: 'Maria',
    email: 'm@m.com',
    phone: '0917',
    role: UserRole.customer);

Rental _rental() => Rental(
      id: 'over-1',
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Gown',
      startDate: DateTime.now().subtract(const Duration(days: 6)),
      endDate: DateTime.now().subtract(const Duration(days: 1)),
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: 'active',
      createdAt: DateTime(2026, 8, 1),
    );

class _FakeRentalRepository implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream.value([_rental()]);

  @override
  Stream<List<Rental>> allRentalsStream() => const Stream.empty();

  @override
  @override
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) =>
      allRentalsStream();

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

class _FakeAppointmentRepository implements AppointmentRepository {
  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) =>
      Stream<List<Appointment>>.value([]);

  @override
  Stream<List<Appointment>> allAppointmentsStream() =>
      Stream<List<Appointment>>.empty();

  @override
  Stream<List<Appointment>> pagedAppointmentsStream({int limit = 20}) =>
      allAppointmentsStream();

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

class _FakeInventoryRepository implements InventoryRepository {
  @override
  Stream<List<CatalogItem>> itemsStream() =>
      Stream<List<CatalogItem>>.value([]);

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

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_user);

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
  Stream<String> emailLinkStream() => const Stream.empty();

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
}

Widget _harness() {
  return MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: _FakeAuthRepository()),
      ChangeNotifierProvider<AuthViewModel>(
        create: (c) => AuthViewModel(c.read<AuthRepository>()),
      ),
      Provider<InventoryRepository>.value(
          value: _FakeInventoryRepository()),
      Provider<RentalRepository>.value(value: _FakeRentalRepository()),
      Provider<AppointmentRepository>.value(
          value: _FakeAppointmentRepository()),
    ],
    child: MaterialApp(
      home: const UserShell(),
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Text('routed')),
      ),
    ),
  );
}

void main() {
  testWidgets('Notifications tab shows feed with bubble', (t) async {
    await t.pumpWidget(_harness());
    await t.pumpAndSettle();
    expect(find.text('Notifications'), findsWidgets);
    await t.tap(find.text('Notifications').last);
    await t.pumpAndSettle();
    expect(find.text('Overdue — Gown'), findsOneWidget);
  });

  testWidgets('tapping overdue row routes to details', (t) async {
    await t.pumpWidget(_harness());
    await t.pumpAndSettle();
    await t.tap(find.text('Notifications').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Overdue — Gown'));
    await t.pumpAndSettle();
    expect(find.text('routed'), findsOneWidget);
  });
}
