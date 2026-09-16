import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/firebase_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/usecases/submit_review_usecase.dart';

class ReviewViewModel extends ChangeNotifier {
  ReviewViewModel({
    required this.submit,
    required this.reviews,
    required this.rental,
    required this.userId,
  }) {
    _sub = reviews.reviewForRentalStream(rental.id).listen((r) {
      _existing = r;
      _loading = false;
      notifyListeners();
    });
  }

  final SubmitReviewUseCase submit;
  final ReviewRepository reviews;
  final Rental rental;
  final String userId;

  StreamSubscription? _sub;
  Review? _existing;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool _savedWithPendingCount = false;

  Review? get existing => _existing;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  bool get savedWithPendingCount => _savedWithPendingCount;

  /// Sends the rating. Returns true when the sheet should close.
  Future<bool> send(int stars, String comment) async {
    if (stars < 1) {
      _error = 'Please choose 1 to 5 stars.';
      notifyListeners();
      return false;
    }
    _submitting = true;
    _error = null;
    _savedWithPendingCount = false;
    notifyListeners();
    try {
      await submit.execute(
        rental: rental,
        userId: userId,
        stars: stars,
        comment: comment,
      );
      return true;
    } on RatingCountPending {
      _savedWithPendingCount = true;
      return true;
    } on FormatException catch (e) {
      _error = e.message;
      return false;
    } on Failure catch (e) {
      _error = e.message;
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
