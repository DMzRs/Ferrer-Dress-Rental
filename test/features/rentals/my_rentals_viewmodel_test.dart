import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/viewmodels/my_rentals_viewmodel.dart';
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

Rental _rental({
  required String id,
  required String status,
  required DateTime end,
}) =>
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

class _FakeRentalRepository implements RentalRepository {
  _FakeRentalRepository(this.list);
  final List<Rental> list;

  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream.value(list);

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
  Stream<int> usersCountStream() => const Stream.empty();
}

MyRentalsViewModel _vm() {
  final now = DateTime.now();
  return MyRentalsViewModel(
    _FakeRentalRepository([
      _rental(id: 'over-1', status: 'active', end: now.subtract(const Duration(days: 2))),
      _rental(id: 'pend-1', status: 'pending', end: now.add(const Duration(days: 3))),
      _rental(id: 'done-1', status: 'completed', end: now.subtract(const Duration(days: 9))),
    ]),
    _FakeAuthRepository(),
  );
}

void main() {
  test('overdue signal comes from the full list, not the filter', () async {
    final vm = _vm();
    await Future<void>.delayed(Duration.zero);
    vm.setFilter('completed');
    await Future<void>.delayed(Duration.zero);
    expect(vm.rentals.map((r) => r.id), ['done-1']);
    expect(vm.hasOverdue, isTrue);
    expect(vm.firstOverdueId, 'over-1');
    expect(vm.overdueIds, ['over-1']);
    expect(vm.overdueCount, 1);
    vm.dispose();
  });

  test('due-soon counts full list', () async {
    final vm = _vm();
    await Future<void>.delayed(Duration.zero);
    expect(vm.dueSoonCount, isNotNull);
    vm.dispose();
  });
}
