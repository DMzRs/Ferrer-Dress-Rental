import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';

abstract class ReviewDataSource {
  Stream<Review?> reviewForRentalStream(String rentalId);

  Stream<List<Review>> itemReviewsStream(String itemId);

  Stream<RatingSummary> ratingSummaryStream(String itemId);

  Future<void> saveReview(Review review);
}
