import 'package:ferrer_rental_shop/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new doc gets role customer plus profile', () {
    final data = buildLinkSignupWrite(
      exists: false,
      email: 'maria@example.com',
      fullName: 'Maria Santos',
      phone: '0917',
    );
    expect(data['role'], 'customer');
    expect(data['fullName'], 'Maria Santos');
    expect(data['phone'], '0917');
    expect(data['email'], 'maria@example.com');
  });

  test('existing doc gains missing name but keeps its role', () {
    final data = buildLinkSignupWrite(
      exists: true,
      email: 'maria@example.com',
      fullName: 'Maria Santos',
      phone: '',
    );
    expect(data['fullName'], 'Maria Santos');
    expect(data.containsKey('role'), isFalse);
    expect(data.containsKey('phone'), isFalse);
  });

  test('empty name never clobbers an existing profile', () {
    final data = buildLinkSignupWrite(
      exists: true,
      email: 'maria@example.com',
      fullName: '',
      phone: '',
    );
    expect(data.containsKey('fullName'), isFalse);
    expect(data['email'], 'maria@example.com');
  });
}
