import 'dart:async';

import 'package:ferrer_rental_shop/features/reviews/data/datasources/review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';

class MockReviewDataSource implements ReviewDataSource {
  MockReviewDataSource() {
    final now = DateTime.now();
    _reviews['rnt-seed-1'] = Review(
      rentalId: 'rnt-seed-1',
      userId: 'user-001',
      userName: 'Maria Santos',
      itemId: 'itm-02',
      itemName: 'Ivory Lace Wedding Gown',
      stars: 5,
      comment: 'Perfect fit, on time.',
      createdAt: now.subtract(const Duration(days: 20)),
    );
    _reviews['rnt-seed-2'] = Review(
      rentalId: 'rnt-seed-2',
      userId: 'user-002',
      userName: 'Ana',
      itemId: 'itm-02',
      itemName: 'Ivory Lace Wedding Gown',
      stars: 4,
      createdAt: now.subtract(const Duration(days: 40)),
    );
  }

  final Map<String, Review> _reviews = {};
  final StreamController<void> _tick = StreamController<void>.broadcast();

  void _emit() => _tick.add(null);

  @override
  Stream<Review?> reviewForRentalStream(String rentalId) async* {
    yield _reviews[rentalId];
    await for (final _ in _tick.stream) {
      yield _reviews[rentalId];
    }
  }

  @override
  Stream<List<Review>> itemReviewsStream(String itemId) async* {
    yield _forItem(itemId);
    await for (final _ in _tick.stream) {
      yield _forItem(itemId);
    }
  }

  @override
  Stream<List<Review>> allReviewsStream() async* {
    yield _all();
    await for (final _ in _tick.stream) {
      yield _all();
    }
  }

  @override
  Stream<RatingSummary> ratingSummaryStream(String itemId) async* {
    yield _summary(itemId);
    await for (final _ in _tick.stream) {
      yield _summary(itemId);
    }
  }

  @override
  Future<void> saveReview(Review review) async {
    _reviews[review.rentalId] = Review(
      rentalId: review.rentalId,
      userId: review.userId,
      userName: review.userName,
      itemId: review.itemId,
      itemName: review.itemName,
      stars: review.stars,
      comment: review.comment,
      createdAt:
          _reviews[review.rentalId]?.createdAt ?? review.createdAt,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  List<Review> _forItem(String itemId) {
    final list = _reviews.values.where((r) => r.itemId == itemId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(5).toList();
  }

  List<Review> _allForItem(String itemId) {
    final list = _reviews.values.where((r) => r.itemId == itemId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Review> _all() {
    final list = _reviews.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  RatingSummary _summary(String itemId) {
    final list = _allForItem(itemId);
    if (list.isEmpty) return RatingSummary.empty;
    return RatingSummary(
      list.map((r) => r.stars).reduce((a, b) => a + b) / list.length,
      list.length,
    );
  }
}
