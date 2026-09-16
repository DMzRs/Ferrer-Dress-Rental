import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:ferrer_rental_shop/features/reviews/presentation/widgets/item_rating_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _harness(String itemId) {
  return Provider<ReviewRepository>.value(
    value: ReviewRepositoryImpl(MockReviewDataSource()),
    child: MaterialApp(
      home: Scaffold(body: ItemRatingHeader(itemId: itemId)),
    ),
  );
}

void main() {
  testWidgets('shows average and count for rated item', (t) async {
    await t.pumpWidget(_harness('itm-02'));
    await t.pumpAndSettle();
    expect(find.text('★ 4.5 (2)'), findsOneWidget);
  });

  testWidgets('shows empty state for unrated item', (t) async {
    await t.pumpWidget(_harness('itm-unknown'));
    await t.pumpAndSettle();
    expect(find.text('No reviews yet'), findsOneWidget);
  });
}
