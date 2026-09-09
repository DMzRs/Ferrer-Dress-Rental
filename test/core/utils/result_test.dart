import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success reports isSuccess true and no failure', () {
      const r = Success<int>(42);
      expect(r.isSuccess, isTrue);
      expect(r.failure, isNull);
      expect(r.data, 42);
    });

    test('Err reports isSuccess false and exposes failure', () {
      const r = Err<int>(NetworkFailure('no connection'));
      expect(r.isSuccess, isFalse);
      expect(r.failure, isA<NetworkFailure>());
      expect(r.failure!.message, 'no connection');
    });

    test('Failure subtypes carry message and code', () {
      const auth = AuthFailure('denied', code: 'auth/denied');
      const unknown = UnknownFailure('oops');
      expect(auth.code, 'auth/denied');
      expect(auth.toString(), 'denied');
      expect(unknown.message, 'oops');
      expect(unknown.code, isNull);
    });

    test('Result works with nullable / void-ish payloads', () {
      const ok = Success<String>('done');
      expect(ok.data, 'done');
      const err = Err<String>(Failure('bad'));
      expect(err.failure!.message, 'bad');
    });
  });
}
