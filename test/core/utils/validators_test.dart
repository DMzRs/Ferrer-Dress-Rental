import 'package:ferrer_rental_shop/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('returns error for null and empty', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('   '), 'Email is required');
    });

    test('returns error for invalid formats', () {
      expect(Validators.email('plainaddress'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('user@.com'), isNotNull);
      expect(Validators.email('user@domain.'), isNotNull);
    });

    test('accepts valid emails and trims whitespace', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('  user.name+tag@sub.example.co  '), isNull);
      expect(Validators.email('a@b.co'), isNull);
    });
  });

  group('Validators.password', () {
    test('returns error for null and empty', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password(''), 'Password is required');
    });

    test('rejects passwords shorter than 6 chars', () {
      expect(Validators.password('12345'), 'Password must be at least 6 characters');
      expect(Validators.password('abc'), isNotNull);
    });

    test('accepts passwords with 6+ chars', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('securePassword123'), isNull);
    });
  });

  group('Validators.fullName', () {
    test('returns error for null and empty', () {
      expect(Validators.fullName(null), 'Full name is required');
      expect(Validators.fullName(''), 'Full name is required');
      expect(Validators.fullName('  '), 'Full name is required');
    });

    test('rejects names shorter than 3 chars', () {
      expect(Validators.fullName('Al'), 'Please enter your complete name');
    });

    test('accepts valid names', () {
      expect(Validators.fullName('Ana'), isNull);
      expect(Validators.fullName('Juan Dela Cruz'), isNull);
    });
  });

  group('Validators.phone', () {
    test('returns error for null and empty', () {
      expect(Validators.phone(null), 'Phone number is required');
      expect(Validators.phone(''), 'Phone number is required');
    });

    test('rejects numbers with fewer than 10 digits', () {
      expect(Validators.phone('123456789'), 'Enter a valid phone number');
      expect(Validators.phone('abc'), isNotNull);
      expect(Validators.phone(''), isNotNull);
    });

    test('accepts formatted numbers with 10+ digits', () {
      expect(Validators.phone('09171234567'), isNull);
      expect(Validators.phone('+63 917 123 4567'), isNull);
      expect(Validators.phone('(02) 8123-4567'), isNull);
    });
  });

  group('Validators.notEmpty', () {
    test('uses default label', () {
      expect(Validators.notEmpty(null), 'This field is required');
      expect(Validators.notEmpty('  '), 'This field is required');
    });

    test('uses custom label', () {
      expect(Validators.notEmpty('', label: 'Address'), 'Address is required');
      expect(Validators.notEmpty('QC', label: 'Address'), isNull);
    });
  });

  group('Validators.positiveNumber', () {
    test('returns error for null and empty', () {
      expect(Validators.positiveNumber(null), 'Amount is required');
      expect(Validators.positiveNumber('  '), 'Amount is required');
    });

    test('rejects zero, negative, and non-numeric', () {
      expect(Validators.positiveNumber('0'), 'Enter a valid Amount');
      expect(Validators.positiveNumber('-5'), 'Enter a valid Amount');
      expect(Validators.positiveNumber('abc'), 'Enter a valid Amount');
    });

    test('accepts positive numbers and custom label', () {
      expect(Validators.positiveNumber('100'), isNull);
      expect(Validators.positiveNumber('99.99'), isNull);
      expect(
        Validators.positiveNumber('-1', label: 'Price'),
        'Enter a valid Price',
      );
    });
  });
}
