import 'package:ferrer_rental_shop/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:ferrer_rental_shop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('watchUsers emits seeded profiles', () async {
    final repo = AuthRepositoryImpl(MockAuthDataSource());
    final users = await repo.watchUsers().first;
    expect(users.map((u) => u.uid), containsAll(['admin-001', 'user-001']));
  });
}
