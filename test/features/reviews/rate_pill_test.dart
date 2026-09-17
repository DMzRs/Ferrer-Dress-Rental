import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/widgets/rental_card.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/usecases/submit_review_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Rental _rental({required String id, String status = 'completed'}) => Rental(
      id: id,
      userId: 'user-001',
      userName: 'Maria Santos',
      itemId: 'itm-02',
      itemName: 'Ivory Lace Wedding Gown',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 5),
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: status,
      createdAt: DateTime(2026, 8, 1),
      returnedAt: status == 'completed' ? DateTime(2026, 8, 6) : null,
    );

Widget _harness(Rental rental) {
  final repo = ReviewRepositoryImpl(MockReviewDataSource());
  return MultiProvider(
    providers: [
      Provider<ReviewRepository>.value(value: repo),
      Provider<SubmitReviewUseCase>(
          create: (c) => SubmitReviewUseCase(c.read<ReviewRepository>())),
    ],
    child: MaterialApp(home: Scaffold(body: RentalCard(rental: rental))),
  );
}

void main() {
  testWidgets('completed unrated rental shows Rate pill', (t) async {
    await t.pumpWidget(_harness(_rental(id: 'rnt-fresh')));
    await t.pumpAndSettle();
    expect(find.text('Rate Item'), findsOneWidget);
  });

  testWidgets('completed rated rental shows stars', (t) async {
    await t.pumpWidget(_harness(_rental(id: 'rnt-seed-1')));
    await t.pumpAndSettle();
    expect(find.textContaining('5.0'), findsOneWidget);
  });

  testWidgets('active rental shows no Rate pill', (t) async {
    await t.pumpWidget(_harness(_rental(id: 'rnt-fresh', status: 'active')));
    await t.pumpAndSettle();
    expect(find.text('Rate Item'), findsNothing);
  });
}
