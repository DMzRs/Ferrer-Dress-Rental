import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/usecases/submit_review_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

Rental _rental({String status = 'completed', String userId = 'u1'}) => Rental(
      id: 'r1',
      userId: userId,
      userName: 'M',
      itemId: 'i1',
      itemName: 'G',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 5),
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: status,
      createdAt: DateTime(2026, 8, 1),
    );

void main() {
  SubmitReviewUseCase usecase() =>
      SubmitReviewUseCase(ReviewRepositoryImpl(MockReviewDataSource()));

  test('saves trimmed review for completed own rental', () async {
    final u = usecase();
    await u.execute(
        rental: _rental(), userId: 'u1', stars: 5, comment: '  Great  ');
    final saved = await u.reviews.reviewForRentalStream('r1').first;
    expect(saved?.stars, 5);
    expect(saved?.comment, 'Great');
  });

  test('rejects pending rental', () {
    expect(
        () => usecase().execute(
            rental: _rental(status: 'active'), userId: 'u1', stars: 5),
        throwsFormatException);
  });

  test('rejects stars outside 1-5', () {
    expect(() => usecase().execute(rental: _rental(), userId: 'u1', stars: 0),
        throwsFormatException);
    expect(() => usecase().execute(rental: _rental(), userId: 'u1', stars: 6),
        throwsFormatException);
  });

  test('rejects other user rental', () {
    expect(
        () => usecase().execute(
            rental: _rental(userId: 'u9'), userId: 'u1', stars: 5),
        throwsFormatException);
  });
}
