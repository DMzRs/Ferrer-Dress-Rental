import 'package:ferrer_rental_shop/features/audit/data/datasources/mock_audit_data_source.dart';
import 'package:ferrer_rental_shop/features/audit/data/repositories/audit_repository_impl.dart';
import 'package:ferrer_rental_shop/features/audit/domain/audit_logger.dart';
import 'package:ferrer_rental_shop/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:ferrer_rental_shop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/viewmodels/accounts_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

AccountsViewModel _vm({RentalRepository? rentals}) {
  final auth = AuthRepositoryImpl(MockAuthDataSource());
  final audit = AuditLogger(
    auth: auth,
    logs: AuditRepositoryImpl(MockAuditDataSource()),
  );
  final vm =
      AccountsViewModel(auth: auth, audit: audit, rentals: rentals);
  addTearDown(() {
    vm.dispose();
    audit.dispose();
  });
  return vm;
}

void main() {
  test('lists seeded users', () async {
    final vm = _vm();
    final users = await vm.usersStream.first;
    expect(users.map((u) => u.uid),
        containsAll(['superadmin-001', 'admin-001', 'user-001']));
  });

  test('createAdmin adds an admin account', () async {
    final vm = _vm();
    final ok = await vm.createAdmin(
      fullName: 'New Admin',
      email: 'newadmin@x.com',
      phone: '0917',
      password: 'secret123',
    );
    expect(ok, isTrue);
    expect(vm.error, isNull);
    final users = await vm.usersStream.first;
    final created = users.firstWhere((u) => u.email == 'newadmin@x.com');
    expect(created.role, UserRole.admin);
  });

  test('createAdmin surfaces duplicate-email errors', () async {
    final vm = _vm();
    final ok = await vm.createAdmin(
      fullName: 'Dupe',
      email: 'admin@ferrer.ph',
      phone: '0917',
      password: 'secret123',
    );
    expect(ok, isFalse);
    expect(vm.error, isNotNull);
  });

  test('changeRole demotes an admin to customer', () async {
    final vm = _vm();
    final users = await vm.usersStream.first;
    final admin = users.firstWhere((u) => u.uid == 'admin-001');
    final ok = await vm.changeRole(admin, UserRole.customer);
    expect(ok, isTrue);
    final updated = (await vm.usersStream.first)
        .firstWhere((u) => u.uid == 'admin-001');
    expect(updated.role, UserRole.customer);
  });

  test('changeRole refuses to demote a superadmin', () async {
    final vm = _vm();
    final users = await vm.usersStream.first;
    final owner = users.firstWhere((u) => u.uid == 'superadmin-001');
    final ok = await vm.changeRole(owner, UserRole.admin);
    expect(ok, isFalse);
    expect(vm.error, isNotNull);
  });

  test('changeRole refuses to promote a customer (fresh accounts only)',
      () async {
    final vm = _vm();
    final users = await vm.usersStream.first;
    final customer = users.firstWhere((u) => u.uid == 'user-001');
    final ok = await vm.changeRole(customer, UserRole.admin);
    expect(ok, isFalse);
    expect(vm.error, contains('fresh'));
  });

  test('pendingDues sums active dues for the account', () async {
    final vm = _vm(rentals: _DuesRentalRepository());
    final dues = await vm.pendingDues('u1');
    expect(dues, isNotNull);
    expect(dues!.count, 2);
    expect(dues.total, 1400);
  });

  test('pendingDues is null without a rental repository', () async {
    final vm = _vm();
    expect(await vm.pendingDues('u1'), isNull);
  });
}

Rental _due(String id, String status) => Rental(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Gown',
      startDate: DateTime(2026, 9, 18),
      endDate: DateTime(2026, 9, 25),
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: status,
      createdAt: DateTime(2026, 9, 17),
    );

class _DuesRentalRepository implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream<List<Rental>>.value([
        _due('r1', 'active'),
        _due('r2', 'pending'),
        _due('r3', 'completed'),
      ]);

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
