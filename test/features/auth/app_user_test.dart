import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser', () {
    test('isAdmin reflects role', () {
      const admin = AppUser(
        uid: 'a1',
        fullName: 'Admin',
        email: 'a@x.com',
        phone: '123',
        role: UserRole.admin,
      );
      const customer = AppUser(
        uid: 'c1',
        fullName: 'Customer',
        email: 'c@x.com',
        phone: '123',
        role: UserRole.customer,
      );
      expect(admin.isAdmin, isTrue);
      expect(customer.isAdmin, isFalse);
    });

    test('initials handles single name, full name, and blanks', () {
      const single = AppUser(
        uid: '1',
        fullName: 'Madonna',
        email: 'e',
        phone: 'p',
        role: UserRole.customer,
      );
      const full = AppUser(
        uid: '2',
        fullName: 'Juan Dela Cruz',
        email: 'e',
        phone: 'p',
        role: UserRole.customer,
      );
      const blank = AppUser(
        uid: '3',
        fullName: '   ',
        email: 'e',
        phone: 'p',
        role: UserRole.customer,
      );
      expect(single.initials, 'M');
      expect(full.initials, 'JC');
      expect(blank.initials, '?');
    });

    test('copyWith keeps uid/email/role and updates rest', () {
      const user = AppUser(
        uid: 'u1',
        fullName: 'Old Name',
        email: 'old@x.com',
        phone: '111',
        address: 'old addr',
        role: UserRole.customer,
      );
      final updated = user.copyWith(
        fullName: 'New Name',
        phone: '222',
        savedPlaces: const ['Home'],
      );
      expect(updated.uid, 'u1');
      expect(updated.email, 'old@x.com');
      expect(updated.fullName, 'New Name');
      expect(updated.phone, '222');
      expect(updated.savedPlaces, ['Home']);
      expect(updated.role, UserRole.customer);
    });
  });
}
