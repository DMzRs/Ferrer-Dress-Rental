import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ferrer_rental_shop/core/constants/firestore_collections.dart';
import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/models/review_model.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';

/// Thrown when the review doc was written but the item aggregate
/// (`avgRating`/`ratingCount`) could not be recomputed after one retry
/// (typically offline). Callers treat the save as successful with a note.
class RatingCountPending extends Failure {
  const RatingCountPending() : super('Rating saved, count updating shortly.');
}

class FirebaseReviewDataSource implements ReviewDataSource {
  FirebaseFirestore get _db => AppFirestore.instance;

  @override
  Stream<Review?> reviewForRentalStream(String rentalId) {
    return _db
        .collection(FirestoreCollections.reviews)
        .doc(rentalId)
        .snapshots()
        .map((d) => d.exists ? ReviewModel.fromMap(d.id, d.data()!) : null);
  }

  @override
  Stream<List<Review>> itemReviewsStream(String itemId) {
    return _db
        .collection(FirestoreCollections.reviews)
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => ReviewModel.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Stream<RatingSummary> ratingSummaryStream(String itemId) {
    return _db.collection(FirestoreCollections.items).doc(itemId).snapshots().map((
      d,
    ) {
      final data = d.data();
      if (data == null) return RatingSummary.empty;
      final count = (data['ratingCount'] as num?)?.toInt() ?? 0;
      final avg = (data['avgRating'] as num?)?.toDouble() ?? 0;
      return RatingSummary(avg, count);
    });
  }

  @override
  Stream<List<Review>> allReviewsStream() {
    return _db
        .collection(FirestoreCollections.reviews)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => ReviewModel.fromMap(d.id, d.data())).toList(),
        );
  }

  @override
  Future<void> saveReview(Review review) async {
    final ref = _db
        .collection(FirestoreCollections.reviews)
        .doc(review.rentalId);
    final data = ReviewModel.fromEntity(review).toMap(forFirestore: true);
    final existing = await ref.get();
    // Overwrites keep the original creation date; the previous star value
    // feeds the aggregate delta below.
    final int? oldStars = existing.exists
        ? (existing.data()!['stars'] as num?)?.toInt()
        : null;
    if (existing.exists) data['createdAt'] = existing.data()!['createdAt'];
    data['updatedAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
    final itemRef = _db
        .collection(FirestoreCollections.items)
        .doc(review.itemId);
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _db.runTransaction((tx) async {
          final itemSnap = await tx.get(itemRef);
          final item = itemSnap.data();
          final count = (item?['ratingCount'] as num?)?.toInt() ?? 0;
          final avg = (item?['avgRating'] as num?)?.toDouble() ?? 0.0;
          var sum = avg * count;
          var newCount = count;
          if (oldStars == null) {
            newCount = count + 1;
            sum += review.stars;
          } else {
            sum += review.stars - oldStars;
          }
          tx.update(itemRef, {
            'avgRating': newCount == 0 ? 0.0 : sum / newCount,
            'ratingCount': newCount,
          });
        });
        return;
      } catch (_) {
        if (attempt == 1) throw const RatingCountPending();
      }
    }
  }
}
