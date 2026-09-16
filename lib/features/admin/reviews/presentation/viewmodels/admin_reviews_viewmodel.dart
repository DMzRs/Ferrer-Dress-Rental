import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';

/// Filter values: 0 = all, otherwise exact star count (5, 4, 3, 2, 1).
class AdminReviewsViewModel extends ChangeNotifier {
  AdminReviewsViewModel(this._reviews);

  final ReviewRepository _reviews;

  Stream<List<Review>> get allReviews => _reviews.allReviewsStream();

  int _filter = 0;
  int get filter => _filter;

  void setFilter(int value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  List<Review> applyFilter(List<Review> reviews) {
    if (_filter == 0) return reviews;
    return reviews.where((r) => r.stars == _filter).toList();
  }

  static double average(List<Review> reviews) {
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.stars).reduce((a, b) => a + b) /
        reviews.length;
  }
}
