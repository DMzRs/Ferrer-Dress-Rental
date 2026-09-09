import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:flutter_test/flutter_test.dart';

CatalogItem _item({String status = 'available', String category = 'dress'}) {
  return CatalogItem(
    id: 'i1',
    name: 'Gown',
    category: category,
    basePrice: 500,
    securityDeposit: 1000,
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('CatalogItem flags', () {
    test('isAvailable only when status is available', () {
      expect(_item(status: 'available').isAvailable, isTrue);
      expect(_item(status: 'rented').isAvailable, isFalse);
      expect(_item(status: 'maintenance').isAvailable, isFalse);
    });

    test('isDress checks category', () {
      expect(_item(category: 'dress').isDress, isTrue);
      expect(_item(category: 'kiddie').isDress, isFalse);
    });
  });

  group('CatalogItem labels', () {
    test('statusLabel maps known statuses', () {
      expect(_item(status: 'rented').statusLabel, 'Rented');
      expect(_item(status: 'maintenance').statusLabel, 'Maintenance');
      expect(
        _item(status: 'scheduled_for_appointment').statusLabel,
        'Scheduled for Appointment',
      );
      expect(_item(status: 'available').statusLabel, 'Available');
      expect(_item(status: 'weird').statusLabel, 'Available');
    });

    test('shortStatusLabel shortens scheduled status', () {
      expect(
        _item(status: 'scheduled_for_appointment').shortStatusLabel,
        'Scheduled',
      );
      expect(_item(status: 'rented').shortStatusLabel, 'Rented');
    });

    test('categoryLabel maps category', () {
      expect(_item(category: 'kiddie').categoryLabel, 'Kiddie Costume');
      expect(_item(category: 'dress').categoryLabel, 'Adult Dress');
      expect(_item(category: 'other').categoryLabel, 'Adult Dress');
    });
  });

  group('CatalogItem.copyWith', () {
    test('overrides only provided fields', () {
      final updated = _item().copyWith(name: 'New Gown', status: 'rented');
      expect(updated.name, 'New Gown');
      expect(updated.status, 'rented');
      expect(updated.id, 'i1');
      expect(updated.basePrice, 500);
    });

    test('preserves lists when not provided', () {
      final item = CatalogItem(
        id: 'i2',
        name: 'Costume',
        category: 'kiddie',
        occasions: const ['party'],
        basePrice: 300,
        securityDeposit: 500,
        sizes: const ['S'],
        createdAt: DateTime(2026, 1, 1),
      );
      final copy = item.copyWith();
      expect(copy.occasions, ['party']);
      expect(copy.sizes, ['S']);
    });
  });
}
