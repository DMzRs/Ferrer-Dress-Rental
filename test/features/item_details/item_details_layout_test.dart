import 'package:ferrer_rental_shop/features/inventory/data/datasources/mock_item_data_source.dart';
import 'package:ferrer_rental_shop/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/item_details/presentation/views/item_details_screen.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _harness(CatalogItem item) {
  return MultiProvider(
    providers: [
      Provider<InventoryRepository>.value(
        value: InventoryRepositoryImpl(MockItemDataSource()),
      ),
      Provider<ReviewRepository>.value(
        value: ReviewRepositoryImpl(MockReviewDataSource()),
      ),
    ],
    child: MaterialApp(home: ItemDetailsScreen(item: item)),
  );
}

CatalogItem _dress() => CatalogItem(
      id: 'itm-02',
      name: 'Ivory Lace Wedding Gown',
      description: 'Elegant gown. ' * 40,
      category: 'dress',
      basePrice: 500,
      securityDeposit: 200,
      sizes: const ['S', 'M', 'L'],
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  testWidgets('size chips stay fully above the bottom bar at max scroll',
      (t) async {
    await t.pumpWidget(_harness(_dress()));
    await t.pumpAndSettle();
    // Scroll to the very end (drag repeatedly until settled).
    for (var i = 0; i < 10; i++) {
      await t.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await t.pumpAndSettle();
    }
    final chipRect = t.getRect(find.text('M'));
    final barRect = t.getRect(find.byKey(const ValueKey('detailsBottomBar')));
    expect(chipRect.bottom, lessThanOrEqualTo(barRect.top));
  });
}
