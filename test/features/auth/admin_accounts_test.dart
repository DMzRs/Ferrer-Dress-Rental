import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:ferrer_rental_shop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createAdmin creates an admin user', () async {
    final repo = AuthRepositoryImpl(MockAuthDataSource());
    final result = await repo.createAdmin(
      fullName: 'New Admin',
      email: 'newadmin@x.com',
      phone: '0917',
      password: 'secret123',
    );
    expect(result.isSuccess, isTrue);
    final user = (result as Success<AppUser>).data;
    expect(user.role, UserRole.admin);
    expect(user.email, 'newadmin@x.com');
  });

  test('updateUserRole refuses customer-to-admin promotion', () async {
    final repo = AuthRepositoryImpl(MockAuthDataSource());
    final result =
        await repo.updateUserRole(uid: 'user-001', role: UserRole.admin);
    expect(result.isSuccess, isFalse);
  });

  test('updateUserRole demotes an admin to customer', () async {
    final repo = AuthRepositoryImpl(MockAuthDataSource());
    final result =
        await repo.updateUserRole(uid: 'admin-001', role: UserRole.customer);
    expect(result.isSuccess, isTrue);
    expect((result as Success<AppUser>).data.role, UserRole.customer);
  });

  test('updateUserRole refuses to demote a superadmin', () async {
    final repo = AuthRepositoryImpl(MockAuthDataSource());
    final result =
        await repo.updateUserRole(uid: 'superadmin-001', role: UserRole.admin);
    expect(result.isSuccess, isFalse);
  });
}
