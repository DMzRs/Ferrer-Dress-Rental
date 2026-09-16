import 'package:ferrer_rental_shop/features/inventory/data/models/catalog_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses rating aggregate, defaults to zero', () {
    final rated = CatalogItemModel.fromMap('i1', {
      'name': 'Gown',
      'category': 'dress',
      'basePrice': 500,
      'securityDeposit': 1000,
      'createdAt': DateTime(2026, 1, 1),
      'avgRating': 4.5,
      'ratingCount': 12,
    });
    expect(rated.avgRating, 4.5);
    expect(rated.ratingCount, 12);
    final plain = CatalogItemModel.fromMap('i2', {'name': 'G'});
    expect(plain.avgRating, 0);
    expect(plain.ratingCount, 0);
  });
}
