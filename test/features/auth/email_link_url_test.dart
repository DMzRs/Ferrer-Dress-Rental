import 'package:flutter_test/flutter_test.dart';

/// Guards the app's link pipeline: the OS hands us a handler URL as a
/// string, app_links parses it to Uri, and we pass uri.toString() to
/// Firebase. If any layer rewrote query parameters, Firebase would reject
/// the oobCode as invalid-action-code.
void main() {
  test('handler URL survives Uri round-trip with params intact', () {
    const raw =
        'https://ferrer-rental-shop.firebaseapp.com/__/auth/handler'
        '?apiKey=AIzaSyTESTKEY1234567890'
        '&oobCode=ABcDeFgHiJkLmNoPqRsTuVwXyZ0123456789-_ABcDeFgH'
        '&mode=signIn'
        '&continueUrl=https%3A%2F%2Fferrer-rental-shop.firebaseapp.com%2F__%2Fauth%2Fhandler';
    final uri = Uri.parse(raw);
    final again = Uri.parse(uri.toString());
    expect(again.queryParameters['mode'], 'signIn');
    expect(
      again.queryParameters['oobCode'],
      'ABcDeFgHiJkLmNoPqRsTuVwXyZ0123456789-_ABcDeFgH',
    );
    expect(
      again.queryParameters['apiKey'],
      'AIzaSyTESTKEY1234567890',
    );
    expect(again.queryParameters['continueUrl'], contains('auth/handler'));
  });
}
