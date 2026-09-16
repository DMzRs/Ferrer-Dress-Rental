import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:flutter_test/flutter_test.dart';

Review _r(String rental, String item, int stars) => Review(
      rentalId: rental, userId: 'u1', itemId: item, stars: stars,
      createdAt: DateTime(2026, 9, 1),
    );

void main() {
  test('saveReview then streams return it; summary aggregates', () async {
    final repo = ReviewRepositoryImpl(MockReviewDataSource());
    await repo.saveReview(_r('r1', 'i1', 5));
    await repo.saveReview(_r('r2', 'i1', 3));
    expect((await repo.reviewForRentalStream('r1').first)?.stars, 5);
    final summary = await repo.ratingSummaryStream('i1').first;
    expect(summary.count, 2);
    expect(summary.avg, 4.0);
    final list = await repo.itemReviewsStream('i1').first;
    expect(list.length, 2);
  });

  test('overwrite keeps single doc per rental', () async {
    final repo = ReviewRepositoryImpl(MockReviewDataSource());
    await repo.saveReview(_r('r1', 'i1', 2));
    await repo.saveReview(_r('r1', 'i1', 5));
    final summary = await repo.ratingSummaryStream('i1').first;
    expect(summary.count, 1);
    expect(summary.avg, 5.0);
  });

  test('allReviewsStream returns newest first', () async {
    final repo = ReviewRepositoryImpl(MockReviewDataSource());
    final all = await repo.allReviewsStream().first;
    expect(all.length, 2);
    expect(
      all[0].createdAt.isAfter(all[1].createdAt) ||
          all[0].createdAt.isAtSameMomentAs(all[1].createdAt),
      isTrue,
    );
  });
}
