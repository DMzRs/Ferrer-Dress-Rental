import 'package:ferrer_rental_shop/features/admin/reviews/presentation/viewmodels/admin_reviews_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/reviews/presentation/views/admin_reviews_screen.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _harness() {
  final repo = ReviewRepositoryImpl(MockReviewDataSource());
  return MultiProvider(
    providers: [
      Provider<ReviewRepository>.value(value: repo),
      ChangeNotifierProvider<AdminReviewsViewModel>(
        create: (c) =>
            AdminReviewsViewModel(c.read<ReviewRepository>()),
      ),
    ],
    child: const MaterialApp(home: AdminReviewsScreen()),
  );
}

void main() {
  testWidgets('lists seeded reviews with summary header', (t) async {
    await t.pumpWidget(_harness());
    await t.pumpAndSettle();
    expect(find.text('Customer Reviews'), findsOneWidget);
    expect(find.textContaining('(2)'), findsOneWidget);
    expect(find.text('Perfect fit, on time.'), findsOneWidget);
  });

  testWidgets('5-star filter narrows the list', (t) async {
    await t.pumpWidget(_harness());
    await t.pumpAndSettle();
    await t.tap(find.text('5★'));
    await t.pumpAndSettle();
    expect(find.text('Perfect fit, on time.'), findsOneWidget);
    expect(find.textContaining('Ivory Lace'), findsOneWidget);
  });
}
