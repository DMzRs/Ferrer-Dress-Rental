import 'package:ferrer_rental_shop/features/inventory/data/models/catalog_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatalogItemModel.fromMap', () {
    test('parses full map with DateTime createdAt', () {
      final model = CatalogItemModel.fromMap('id1', {
        'name': 'Gown',
        'description': 'Elegant',
        'category': 'dress',
        'occasions': ['wedding', 'party'],
        'basePrice': 500,
        'securityDeposit': 1000,
        'sizes': ['S', 'M'],
        'thumbnail': 'thumb',
        'status': 'rented',
        'createdAt': DateTime(2026, 1, 2),
      });
      expect(model.id, 'id1');
      expect(model.name, 'Gown');
      expect(model.occasions, ['wedding', 'party']);
      expect(model.basePrice, 500);
      expect(model.status, 'rented');
      expect(model.isAvailable, isFalse);
    });

    test('applies defaults for missing keys', () {
      final model = CatalogItemModel.fromMap('id2', {});
      expect(model.name, '');
      expect(model.category, 'dress');
      expect(model.occasions, isEmpty);
      expect(model.basePrice, 0);
      expect(model.status, 'available');
      expect(model.isAvailable, isTrue);
    });

    test('parses numeric strings and ISO date strings', () {
      final model = CatalogItemModel.fromMap('id3', {
        'name': 'Costume',
        'category': 'kiddie',
        'basePrice': '350.5',
        'securityDeposit': '700',
        'createdAt': '2026-03-04T00:00:00.000',
      });
      expect(model.basePrice, 350.5);
      expect(model.securityDeposit, 700);
      expect(model.createdAt, DateTime(2026, 3, 4));
    });

    test('coerces non-string list entries via toString', () {
      final model = CatalogItemModel.fromMap('id4', {
        'name': 'X',
        'category': 'dress',
        'occasions': [1, true],
        'sizes': [42],
        'basePrice': 10,
        'securityDeposit': 20,
        'createdAt': DateTime(2026, 1, 1),
      });
      expect(model.occasions, ['1', 'true']);
      expect(model.sizes, ['42']);
    });
  });

  group('CatalogItemModel mapping', () {
    test('fromEntity copies all fields', () {
      final src = CatalogItemModel.fromMap('id5', {
        'name': 'Gown',
        'category': 'dress',
        'basePrice': 100,
        'securityDeposit': 200,
        'createdAt': DateTime(2026, 1, 1),
      });
      final copy = CatalogItemModel.fromEntity(src);
      expect(copy.id, 'id5');
      expect(copy.name, 'Gown');
      expect(copy.basePrice, 100);
    });

    test('toMap round-trips through fromMap (non-firestore)', () {
      final src = CatalogItemModel.fromMap('id6', {
        'name': 'Gown',
        'description': 'd',
        'category': 'dress',
        'occasions': ['wedding'],
        'basePrice': 500,
        'securityDeposit': 1000,
        'sizes': ['M'],
        'thumbnail': 't',
        'status': 'available',
        'createdAt': DateTime(2026, 5, 6),
      });
      final roundTrip = CatalogItemModel.fromMap('id6', src.toMap());
      expect(roundTrip.name, 'Gown');
      expect(roundTrip.occasions, ['wedding']);
      expect(roundTrip.basePrice, 500);
      expect(roundTrip.createdAt, DateTime(2026, 5, 6));
    });
  });
}
