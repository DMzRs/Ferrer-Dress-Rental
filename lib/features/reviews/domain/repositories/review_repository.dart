import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';

class RatingSummary {
  final double avg;
  final int count;

  const RatingSummary(this.avg, this.count);

  static const empty = RatingSummary(0, 0);
}

abstract class ReviewRepository {
  Stream<Review?> reviewForRentalStream(String rentalId);

  Stream<List<Review>> itemReviewsStream(String itemId);

  Stream<RatingSummary> ratingSummaryStream(String itemId);

  Future<void> saveReview(Review review);
}
