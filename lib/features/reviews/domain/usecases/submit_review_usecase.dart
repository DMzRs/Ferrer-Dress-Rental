import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/firebase_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';

class SubmitReviewUseCase {
  const SubmitReviewUseCase(this.reviews);

  final ReviewRepository reviews;

  Future<void> execute({
    required Rental rental,
    required String userId,
    required int stars,
    String comment = '',
  }) async {
    if (!rental.isCompleted) {
      throw const FormatException('Only completed rentals can be rated.');
    }
    if (rental.userId != userId) {
      throw const FormatException('You can only rate your own rentals.');
    }
    if (stars < 1 || stars > 5) {
      throw const FormatException('Please choose 1 to 5 stars.');
    }
    var clean = comment.trim();
    if (clean.length > 500) clean = clean.substring(0, 500);
    try {
      await reviews.saveReview(
        Review(
          rentalId: rental.id,
          userId: userId,
          userName: rental.userName,
          itemId: rental.itemId,
          itemName: rental.itemName,
          stars: stars,
          comment: clean,
          createdAt: DateTime.now(),
        ),
      );
    } on RatingCountPending {
      rethrow;
    } catch (_) {
      throw const NetworkFailure(
        'Could not save your rating. Please try again.',
      );
    }
  }
}
