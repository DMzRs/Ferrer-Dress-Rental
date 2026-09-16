import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/firebase_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  const ReviewRepositoryImpl(this._dataSource);

  final ReviewDataSource _dataSource;

  static ReviewDataSource defaultDataSource() {
    if (AppConfig.firebaseEnabled) return FirebaseReviewDataSource();
    return MockReviewDataSource();
  }

  @override
  Stream<Review?> reviewForRentalStream(String rentalId) =>
      _dataSource.reviewForRentalStream(rentalId);

  @override
  Stream<List<Review>> itemReviewsStream(String itemId) =>
      _dataSource.itemReviewsStream(itemId);

  @override
  Stream<RatingSummary> ratingSummaryStream(String itemId) =>
      _dataSource.ratingSummaryStream(itemId);

  @override
  Future<void> saveReview(Review review) => _dataSource.saveReview(review);
}
