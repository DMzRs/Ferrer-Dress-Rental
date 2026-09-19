import 'package:ferrer_rental_shop/core/router/app_router.dart';
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/usecases/submit_review_usecase.dart';
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
      id: 'r1',
      userId: 'u1',
      userName: 'Maria Santos Dela Cruz',
      itemId: 'i1',
      itemName:
          'Ivory Lace Wedding Gown With An Extremely Long Name That Wraps',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: 'pending',
      createdAt: DateTime.now(),
    );

class _FakeRentalRepository implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream<List<Rental>>.value([_rental()]);

  @override
  Stream<List<Rental>> allRentalsStream() =>
      Stream<List<Rental>>.empty();

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

Future<void> _pumpShell(WidgetTester t) async {
  t.view.physicalSize = const Size(360, 640);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MultiProvider(
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
        Provider<ReviewRepository>.value(
            value: ReviewRepositoryImpl(MockReviewDataSource())),
        Provider<SubmitReviewUseCase>(
            create: (c) =>
                SubmitReviewUseCase(c.read<ReviewRepository>())),
      ],
      child: MaterialApp(
        home: const Scaffold(body: Text('home')),
        onGenerateRoute: onGenerateRoute,
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('my-rentals route lands on Rentals tab with nav bar',
      (t) async {
    await _pumpShell(t);
    final nav = Navigator.of(t.element(find.text('home')));
    nav.pushNamedAndRemoveUntil(
      AppRoutes.myRentals,
      (route) => route.isFirst,
      arguments: 'r1',
    );
    await t.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('My Rentals'), findsOneWidget);
    expect(find.textContaining('Ivory Lace'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
