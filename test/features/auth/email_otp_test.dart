import 'package:ferrer_rental_shop/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verifyEmailOtp accepts 123456 in mock mode', () async {
    final ds = MockAuthDataSource();
    await ds.requestEmailOtp('j@x.com');
    await ds.verifyEmailOtp(email: 'j@x.com', code: '123456');
  });
}
