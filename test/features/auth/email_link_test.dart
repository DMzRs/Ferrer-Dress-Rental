import 'package:ferrer_rental_shop/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sendSignInLink then link completes signup in mock mode', () async {
    final ds = MockAuthDataSource();
    await ds.sendSignInLink('newbie@x.com');
    final user = await ds.signInWithEmailLink(
      email: 'newbie@x.com',
      link: 'demo-link',
      fullName: 'New Bie',
      phone: '0918',
    );
    expect(user.email, 'newbie@x.com');
    expect(user.fullName, 'New Bie');
  });

  test('link signs into an existing mock account', () async {
    final ds = MockAuthDataSource();
    await ds.sendSignInLink('maria@example.com');
    final user = await ds.signInWithEmailLink(
      email: 'maria@example.com',
      link: 'demo-link',
    );
    expect(user.uid, 'user-001');
  });

  test('emailLinkStream is empty in mock mode', () async {
    final ds = MockAuthDataSource();
    expect(await ds.emailLinkStream.isEmpty, isTrue);
  });
}
