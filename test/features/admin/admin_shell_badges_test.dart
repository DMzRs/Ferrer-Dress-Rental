import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/admin/admin_shell.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Rental _rental({required String id, required String status, required DateTime end}) =>
    Rental(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Gown',
      startDate: end.subtract(const Duration(days: 4)),
      endDate: end,
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: status,
      createdAt: DateTime(2026, 8, 1),
    );

Appointment _appt() => Appointment(
      id: 'a1',
      userId: 'u1',
      userName: 'Maria',
      purpose: 'Trying On',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      status: Appointment.statusPending,
      createdAt: DateTime(2026, 8, 1),
    );

class _FakeRentalRepository implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream<List<Rental>>.empty();

  @override
  Stream<List<Rental>> allRentalsStream() {
    final now = DateTime.now();
    return Stream.value([
      _rental(id: 'pend-1', status: 'pending', end: now.add(const Duration(days: 3))),
      _rental(id: 'over-1', status: 'active', end: now.subtract(const Duration(days: 1))),
    ]);
  }

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
      Stream<List<Appointment>>.empty();

  @override
  Stream<List<Appointment>> allAppointmentsStream() =>
      Stream.value([_appt()]);

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
  Stream<AppUser?> get authStateChanges => Stream.value(const AppUser(
      uid: 'admin-1',
      fullName: 'Ms Ferrer',
      email: 'admin@ferrer.ph',
      phone: '0917',
      role: UserRole.admin));

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
}

bool _badgeWith(WidgetTester t, String label) => find
    .byWidgetPredicate((w) =>
        w is Badge && (w.label as Text?)?.data == label)
    .evaluate()
    .isNotEmpty;

void main() {
  testWidgets('shell tabs badge pending and overdue queues', (t) async {
    final rentals = _FakeRentalRepository();
    final inventory = _FakeInventoryRepository();
    final appointments = _FakeAppointmentRepository();
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<RentalRepository>.value(value: rentals),
          Provider<InventoryRepository>.value(value: inventory),
          Provider<AppointmentRepository>.value(value: appointments),
          Provider<AuthRepository>.value(value: _FakeAuthRepository()),
          Provider<ReviewRepository>.value(
              value: ReviewRepositoryImpl(MockReviewDataSource())),
          ChangeNotifierProvider<AuthViewModel>(
            create: (c) => AuthViewModel(c.read<AuthRepository>()),
          ),
          Provider<ProcessReturnUseCase>(
              create: (c) => ProcessReturnUseCase(
                  c.read<RentalRepository>(),
                  c.read<InventoryRepository>())),
          Provider<ConfirmRentalUseCase>(
              create: (c) =>
                  ConfirmRentalUseCase(c.read<RentalRepository>())),
          Provider<DeclineRentalUseCase>(
              create: (c) => DeclineRentalUseCase(c.read<RentalRepository>(),
                  c.read<InventoryRepository>())),
        ],
        child: const MaterialApp(home: AdminShell()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byType(Badge), findsNWidgets(2));
    expect(_badgeWith(t, '1'), isTrue);
    expect(_badgeWith(t, '2'), isTrue);
    expect(t.takeException(), isNull);
  });
}
