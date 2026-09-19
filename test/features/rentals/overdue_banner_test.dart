import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/viewmodels/my_rentals_viewmodel.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/views/my_rentals_screen.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/usecases/submit_review_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Rental _rental({required String id, required String status, required DateTime end}) =>
    Rental(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Gown $id',
      startDate: end.subtract(const Duration(days: 4)),
      endDate: end,
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: status,
      createdAt: DateTime(2026, 8, 1),
    );

class _FakeRentalRepository implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) {
    final now = DateTime.now();
    return Stream.value([
      _rental(id: 'over-1', status: 'active', end: now.subtract(const Duration(days: 2))),
      _rental(id: 'done-1', status: 'completed', end: now.subtract(const Duration(days: 9))),
    ]);
  }

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

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(const AppUser(
      uid: 'u1',
      fullName: 'Maria',
      email: 'm@m.com',
      phone: '0917',
      role: UserRole.customer));

  @override
  Future<Result<AppUser>> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signUp(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<Result<void>> sendSignInLink(String email) => throw UnimplementedError();

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
          {String? fullName, String? phone, String? address, List<String>? savedPlaces}) =>
      throw UnimplementedError();

  @override
  Stream<int> usersCountStream() => const Stream.empty();
}

Widget _harness(MyRentalsViewModel vm) {
  final reviewRepo = ReviewRepositoryImpl(MockReviewDataSource());
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MyRentalsViewModel>.value(value: vm),
      Provider<ReviewRepository>.value(value: reviewRepo),
      Provider<SubmitReviewUseCase>(
          create: (c) => SubmitReviewUseCase(c.read<ReviewRepository>())),
    ],
    child: const MaterialApp(home: Scaffold(body: MyRentalsScreen())),
  );
}

void main() {
  testWidgets('overdue banner shows under Completed filter', (t) async {
    final vm = MyRentalsViewModel(_FakeRentalRepository(), _FakeAuthRepository());
    addTearDown(vm.dispose);
    await t.pumpWidget(_harness(vm));
    await t.pumpAndSettle();
    await t.tap(find.text('Completed').first);
    await t.pumpAndSettle();
    expect(
      find.text('1 item overdue — please return it immediately.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping banner jumps to Active', (t) async {
    final vm = MyRentalsViewModel(_FakeRentalRepository(), _FakeAuthRepository());
    addTearDown(vm.dispose);
    await t.pumpWidget(_harness(vm));
    await t.pumpAndSettle();
    await t.tap(find.text('Completed').first);
    await t.pumpAndSettle();
    await t.tap(find.text('1 item overdue — please return it immediately.'));
    await t.pumpAndSettle();
    expect(vm.filter, 'active');
    expect(find.textContaining('Gown over-1'), findsOneWidget);
  });
}
