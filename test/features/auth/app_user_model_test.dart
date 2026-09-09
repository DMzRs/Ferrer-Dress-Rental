import 'package:ferrer_rental_shop/features/auth/data/models/app_user_model.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUserModel', () {
    test('fromMap parses fields and admin role', () {
      final model = AppUserModel.fromMap('uid1', {
        'fullName': 'Jane Doe',
        'email': 'jane@x.com',
        'phone': '0917',
        'address': 'QC',
        'savedPlaces': ['Home', 'Office'],
        'role': 'admin',
      });
      expect(model.uid, 'uid1');
      expect(model.fullName, 'Jane Doe');
      expect(model.savedPlaces, ['Home', 'Office']);
      expect(model.role, UserRole.admin);
      expect(model.isAdmin, isTrue);
    });

    test('fromMap defaults missing fields and non-admin role', () {
      final model = AppUserModel.fromMap('uid2', {});
      expect(model.fullName, '');
      expect(model.email, '');
      expect(model.savedPlaces, isEmpty);
      expect(model.role, UserRole.customer);
    });

    test('toMap serializes role correctly', () {
      final model = AppUserModel.fromMap('uid3', {
        'fullName': 'Bob',
        'email': 'b@x.com',
        'phone': '1',
        'role': 'customer',
      });
      final map = model.toMap();
      expect(map['role'], 'customer');
      expect(map['fullName'], 'Bob');
      expect(map['savedPlaces'], isA<List>());
    });
  });
}
