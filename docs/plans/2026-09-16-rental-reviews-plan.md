# Rental Reviews & Ratings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Customers rate completed rentals (stars + comment, editable) and shoppers see item ratings.

**Architecture:** New `reviews` feature mirroring the rentals clean-architecture split (`domain/entities`, `data/models`, `data/datasources` Firebase+Mock, `data/repositories`, `domain/usecases`, `presentation`). One doc per rental (`reviews/{rentalId}`); item aggregates recomputed client-side in a Firestore transaction. UI hooks into existing completed surfaces only.

**Tech Stack:** Flutter 3.47 / Dart 3.13, cloud_firestore, provider (ChangeNotifier), flutter_test.

**Spec:** `docs/specs/2026-09-16-rental-reviews-design.md` — read it before starting; on any conflict the spec wins.

## Global Constraints

- Null-safety, `flutter analyze` clean, full `flutter test` green before each commit.
- Follow existing file patterns exactly (`RentalModel` parsing helpers, `*RepositoryImpl.defaultDataSource()` via `AppConfig.firebaseEnabled`, `FormatException` for guard violations, `NetworkFailure` for IO errors).
- Commit after every task (`git add <task files>`, message per task).
- Never break existing test fakes: do NOT add methods to `RentalRepository` or `InventoryRepository`.
- `docs/superpowers/` is gitignored scratch — plan/spec live under `docs/`.

---

### Task 1: Review entity, model, collection constant

**Files:**
- Create: `lib/features/reviews/domain/entities/review_entity.dart`
- Create: `lib/features/reviews/data/models/review_model.dart`
- Modify: `lib/core/constants/firestore_collections.dart` (add `reviews`)
- Test: `test/features/reviews/review_model_test.dart`

**Interfaces:**
- Consumes: nothing (greenfield).
- Produces: `Review` (rentalId, userId, userName, itemId, itemName, stars, comment, createdAt, updatedAt, `hasComment`), `ReviewModel.fromMap(docId, map) / fromEntity(r) / toMap({forFirestore})`, `FirestoreCollections.reviews`.

- [ ] **Step 1: Write the failing test** — `test/features/reviews/review_model_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/features/reviews/data/models/review_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap parses full map, doc id becomes rentalId', () {
    final m = ReviewModel.fromMap('rnt-1', {
      'userId': 'u1',
      'userName': 'Maria',
      'itemId': 'i1',
      'itemName': 'Gown',
      'stars': 4,
      'comment': 'Lovely fit',
      'createdAt': DateTime(2026, 9, 1),
    });
    expect(m.rentalId, 'rnt-1');
    expect(m.stars, 4);
    expect(m.hasComment, isTrue);
  });

  test('fromMap defaults missing comment/stars safely', () {
    final m = ReviewModel.fromMap('rnt-2', {'userId': 'u1'});
    expect(m.comment, '');
    expect(m.stars, 0);
    expect(m.hasComment, isFalse);
  });

  test('toMap(forFirestore: true) encodes dates as Timestamp', () {
    final m = ReviewModel.fromEntity(ReviewModel(
      rentalId: 'rnt-1', userId: 'u1', userName: 'M', itemId: 'i1',
      itemName: 'G', stars: 5, createdAt: DateTime(2026, 9, 1),
    ));
    final map = m.toMap(forFirestore: true);
    expect(map['createdAt'], isA<Timestamp>());
    expect(map['stars'], 5);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reviews/review_model_test.dart`
Expected: FAIL — file not found / class undefined.

- [ ] **Step 3: Write minimal implementation** — entity:

```dart
class Review {
  final String rentalId;
  final String userId;
  final String userName;
  final String itemId;
  final String itemName;
  final int stars;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Review({
    required this.rentalId,
    required this.userId,
    this.userName = '',
    required this.itemId,
    this.itemName = '',
    this.stars = 0,
    this.comment = '',
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasComment => comment.trim().isNotEmpty;
}
```

Model (`ReviewModel extends Review`, mirrors `RentalModel` helpers):

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.rentalId,
    required super.userId,
    super.userName,
    required super.itemId,
    super.itemName,
    super.stars,
    super.comment,
    required super.createdAt,
    super.updatedAt,
  });

  factory ReviewModel.fromMap(String docId, Map<String, dynamic> map) {
    return ReviewModel(
      rentalId: docId,
      userId: (map['userId'] ?? '') as String,
      userName: (map['userName'] ?? '') as String,
      itemId: (map['itemId'] ?? '') as String,
      itemName: (map['itemName'] ?? '') as String,
      stars: _toInt(map['stars']),
      comment: (map['comment'] ?? '') as String,
      createdAt: _toDate(map['createdAt']),
      updatedAt: map['updatedAt'] == null ? null : _toDate(map['updatedAt']),
    );
  }

  factory ReviewModel.fromEntity(Review r) => ReviewModel(
        rentalId: r.rentalId, userId: r.userId, userName: r.userName,
        itemId: r.itemId, itemName: r.itemName, stars: r.stars,
        comment: r.comment, createdAt: r.createdAt, updatedAt: r.updatedAt,
      );

  Map<String, dynamic> toMap({bool forFirestore = false}) {
    dynamic encode(DateTime d) =>
        forFirestore ? Timestamp.fromDate(d) : d.toIso8601String();
    return {
      'userId': userId, 'userName': userName, 'itemId': itemId,
      'itemName': itemName, 'stars': stars, 'comment': comment,
      'createdAt': encode(createdAt),
      if (updatedAt != null) 'updatedAt': encode(updatedAt!),
    };
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
```

Constant — append to `FirestoreCollections`: `static const reviews = 'reviews';`

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reviews/review_model_test.dart`
Expected: PASS (3/3).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reviews/domain/entities/review_entity.dart lib/features/reviews/data/models/review_model.dart lib/core/constants/firestore_collections.dart test/features/reviews/review_model_test.dart
git commit -m "Add Review entity, model, and collection constant"
```

### Task 2: Repository, datasources (Firebase + Mock), rating summary

**Files:**
- Create: `lib/features/reviews/domain/repositories/review_repository.dart`
- Create: `lib/features/reviews/data/datasources/review_data_source.dart`
- Create: `lib/features/reviews/data/datasources/firebase_review_data_source.dart`
- Create: `lib/features/reviews/data/datasources/mock_review_data_source.dart`
- Create: `lib/features/reviews/data/repositories/review_repository_impl.dart`
- Test: `test/features/reviews/review_repository_test.dart`

**Interfaces:**
- Consumes: `Review`, `ReviewModel`, `FirestoreCollections.reviews` (Task 1).
- Produces: `RatingSummary(avg, count)`, `ReviewRepository{reviewForRentalStream, itemReviewsStream, ratingSummaryStream, saveReview}`, `ReviewRepositoryImpl.defaultDataSource()`, `RatingCountPending extends Failure` (review saved, aggregate retry exhausted).

- [ ] **Step 1: Write the failing test** — delegation + mock behavior via fakes:

```dart
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reviews/review_repository_test.dart`
Expected: FAIL — types undefined.

- [ ] **Step 3: Write minimal implementation**

`domain/repositories/review_repository.dart`:

```dart
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
```

`data/datasources/review_data_source.dart` — same four signatures returning `ReviewModel`/`(double,int)`-free shapes: keep it identical to the repository but with `Review` types (thin interface; impl classes map models internally).

`data/repositories/review_repository_impl.dart`:

```dart
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
  Stream<Review?> reviewForRentalStream(String id) =>
      _dataSource.reviewForRentalStream(id);
  @override
  Stream<List<Review>> itemReviewsStream(String itemId) =>
      _dataSource.itemReviewsStream(itemId);
  @override
  Stream<RatingSummary> ratingSummaryStream(String itemId) =>
      _dataSource.ratingSummaryStream(itemId);
  @override
  Future<void> saveReview(Review review) => _dataSource.saveReview(review);
}
```

`firebase_review_data_source.dart` (full):

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/core/constants/firestore_collections.dart';
import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/models/review_model.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';

class RatingCountPending extends Failure {
  const RatingCountPending()
      : super('Rating saved, count updating shortly.');
}

class FirebaseReviewDataSource implements ReviewDataSource {
  FirebaseFirestore get _db => AppFirestore.instance;

  @override
  Stream<Review?> reviewForRentalStream(String rentalId) {
    return _db.collection(FirestoreCollections.reviews).doc(rentalId)
        .snapshots()
        .map((d) => d.exists ? ReviewModel.fromMap(d.id, d.data()!) : null);
  }

  @override
  Stream<List<Review>> itemReviewsStream(String itemId) {
    return _db.collection(FirestoreCollections.reviews)
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ReviewModel.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<RatingSummary> ratingSummaryStream(String itemId) {
    return _db.collection(FirestoreCollections.items).doc(itemId)
        .snapshots()
        .map((d) {
      final data = d.data();
      if (data == null) return RatingSummary.empty;
      final count = (data['ratingCount'] as num?)?.toInt() ?? 0;
      final avg = (data['avgRating'] as num?)?.toDouble() ?? 0;
      return RatingSummary(avg, count);
    });
  }

  @override
  Future<void> saveReview(Review review) async {
    final ref = _db.collection(FirestoreCollections.reviews).doc(review.rentalId);
    final data = ReviewModel.fromEntity(review).toMap(forFirestore: true);
    final existing = await ref.get();
    if (existing.exists) data['createdAt'] = existing.data()!['createdAt'];
    data['updatedAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _db.runTransaction((tx) async {
          final snap = await tx.get(_db
              .collection(FirestoreCollections.reviews)
              .where('itemId', isEqualTo: review.itemId));
          final stars = snap.docs.map((d) => (d.data()['stars'] as num?)?.toInt() ?? 0).toList();
          final count = stars.length;
          final avg = count == 0 ? 0.0 : stars.reduce((a, b) => a + b) / count;
          tx.update(_db.collection(FirestoreCollections.items).doc(review.itemId),
              {'avgRating': avg, 'ratingCount': count});
        });
        return;
      } catch (_) {
        if (attempt == 1) throw const RatingCountPending();
      }
    }
  }
}
```

`mock_review_data_source.dart` — in-memory map keyed by rentalId, broadcast controller, 2 seeded samples (`rnt-seed-1/i-seed 5★`, `rnt-seed-2/i-seed 4★`), `saveReview` overwrites + re-emits, summary computed inline, `updatedAt` set to `DateTime.now()`:

```dart
import 'dart:async';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';

class MockReviewDataSource implements ReviewDataSource {
  MockReviewDataSource() {
    final now = DateTime.now();
    _reviews['rnt-seed-1'] = Review(rentalId: 'rnt-seed-1', userId: 'user-001',
        userName: 'Maria Santos', itemId: 'itm-02', itemName: 'Ivory Lace Wedding Gown',
        stars: 5, comment: 'Perfect fit, on time.', createdAt: now.subtract(const Duration(days: 20)));
    _reviews['rnt-seed-2'] = Review(rentalId: 'rnt-seed-2', userId: 'user-002',
        userName: 'Ana', itemId: 'itm-02', itemName: 'Ivory Lace Wedding Gown',
        stars: 4, createdAt: now.subtract(const Duration(days: 40)));
  }

  final Map<String, Review> _reviews = {};
  final StreamController<void> _tick = StreamController<void>.broadcast();
  void _emit() => _tick.add(null);

  @override
  Stream<Review?> reviewForRentalStream(String rentalId) async* {
    yield _reviews[rentalId];
    await for (final _ in _tick.stream) yield _reviews[rentalId];
  }

  @override
  Stream<List<Review>> itemReviewsStream(String itemId) async* {
    yield _forItem(itemId);
    await for (final _ in _tick.stream) yield _forItem(itemId);
  }

  @override
  Stream<RatingSummary> ratingSummaryStream(String itemId) async* {
    yield _summary(itemId);
    await for (final _ in _tick.stream) yield _summary(itemId);
  }

  @override
  Future<void> saveReview(Review review) async {
    _reviews[review.rentalId] = Review(
      rentalId: review.rentalId, userId: review.userId, userName: review.userName,
      itemId: review.itemId, itemName: review.itemName, stars: review.stars,
      comment: review.comment, createdAt: _reviews[review.rentalId]?.createdAt ?? review.createdAt,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  List<Review> _forItem(String itemId) {
    final list = _reviews.values.where((r) => r.itemId == itemId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  RatingSummary _summary(String itemId) {
    final list = _forItem(itemId);
    if (list.isEmpty) return RatingSummary.empty;
    return RatingSummary(
        list.map((r) => r.stars).reduce((a, b) => a + b) / list.length, list.length);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reviews/review_repository_test.dart`
Expected: PASS (2/2).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reviews/domain/repositories lib/features/reviews/data/datasources lib/features/reviews/data/repositories test/features/reviews/review_repository_test.dart
git commit -m "Add review repository with Firebase and mock datasources"
```

### Task 3: CatalogItem aggregate fields

**Files:**
- Modify: `lib/features/inventory/domain/entities/catalog_item.dart`
- Modify: `lib/features/inventory/data/models/catalog_item_model.dart` (mirror existing parse pattern; read file first, add `avgRating`/`ratingCount` with `0` defaults in fromMap/fromEntity/toMap/copyWith)
- Test: extend `test/features/inventory/catalog_item_model_test.dart` (read first) OR new `test/features/inventory/catalog_item_rating_test.dart` (prefer new file, no edits to existing tests)

**Interfaces:**
- Consumes: nothing new.
- Produces: `CatalogItem.avgRating (default 0)`, `CatalogItem.ratingCount (default 0)`.

- [ ] **Step 1: Write the failing test** — `test/features/inventory/catalog_item_rating_test.dart`:

```dart
import 'package:ferrer_rental_shop/features/inventory/data/models/catalog_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses rating aggregate, defaults to zero', () {
    final rated = CatalogItemModel.fromMap('i1', {
      'name': 'Gown', 'category': 'dress', 'basePrice': 500,
      'securityDeposit': 1000, 'createdAt': DateTime(2026, 1, 1),
      'avgRating': 4.5, 'ratingCount': 12,
    });
    expect(rated.avgRating, 4.5);
    expect(rated.ratingCount, 12);
    final plain = CatalogItemModel.fromMap('i2', {'name': 'G'});
    expect(plain.avgRating, 0);
    expect(plain.ratingCount, 0);
  });
}
```

Check `CatalogItemModel.fromMap` signature in the model file before running (the existing test calls it with `fromMap(map)` or `fromMap(id, map)` — match whatever exists; the rentals model uses `(id, map)`).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/inventory/catalog_item_rating_test.dart`
Expected: FAIL — getters undefined (adjust fromMap arity to match the real file).

- [ ] **Step 3: Write minimal implementation** — add to entity (constructor defaults + copyWith):

```dart
final double avgRating;
final int ratingCount;
// constructor: this.avgRating = 0, this.ratingCount = 0,
// copyWith: avgRating: avgRating ?? this.avgRating, ratingCount: ratingCount ?? this.ratingCount,
```

Model: parse with `_toDouble(map['avgRating'])` / `_toInt(map['ratingCount'])` following that file's existing helpers, include in `toMap`/`fromEntity`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/inventory/catalog_item_rating_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/domain/entities/catalog_item.dart lib/features/inventory/data/models/catalog_item_model.dart test/features/inventory/catalog_item_rating_test.dart
git commit -m "Add rating aggregate fields to catalog item"
```

### Task 4: SubmitReviewUseCase with guards

**Files:**
- Create: `lib/features/reviews/domain/usecases/submit_review_usecase.dart`
- Test: `test/features/reviews/submit_review_usecase_test.dart`

**Interfaces:**
- Consumes: `ReviewRepository.saveReview`, `Rental{isCompleted, userId, itemId, itemName}`.
- Produces: `SubmitReviewUseCase.execute({required Rental rental, required String userId, required int stars, String comment = ''})` — throws `FormatException` on guard violations, `NetworkFailure` on IO, rethrows `RatingCountPending`.

- [ ] **Step 1: Write the failing test**:

```dart
import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/usecases/submit_review_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

Rental _rental({String status = 'completed', String userId = 'u1'}) => Rental(
      id: 'r1', userId: userId, userName: 'M', itemId: 'i1', itemName: 'G',
      startDate: DateTime(2026, 8, 1), endDate: DateTime(2026, 8, 5),
      rentalFee: 500, securityDeposit: 200, total: 700,
      status: status, createdAt: DateTime(2026, 8, 1),
    );

void main() {
  SubmitReviewUseCase usecase() =>
      SubmitReviewUseCase(ReviewRepositoryImpl(MockReviewDataSource()));

  test('saves trimmed review for completed own rental', () async {
    final u = usecase();
    await u.execute(rental: _rental(), userId: 'u1', stars: 5, comment: '  Great  ');
    final saved = await u.reviews.reviewForRentalStream('r1').first;
    expect(saved?.stars, 5);
    expect(saved?.comment, 'Great');
  });

  test('rejects pending rental', () {
    expect(() => usecase().execute(rental: _rental(status: 'active'), userId: 'u1', stars: 5),
        throwsFormatException);
  });

  test('rejects stars outside 1-5', () {
    expect(() => usecase().execute(rental: _rental(), userId: 'u1', stars: 0),
        throwsFormatException);
    expect(() => usecase().execute(rental: _rental(), userId: 'u1', stars: 6),
        throwsFormatException);
  });

  test('rejects other user rental', () {
    expect(() => usecase().execute(rental: _rental(userId: 'u9'), userId: 'u1', stars: 5),
        throwsFormatException);
  });
}
```

The test reads `u.reviews` — so expose `final ReviewRepository reviews;` on the usecase (constructor `SubmitReviewUseCase(this.reviews)`).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reviews/submit_review_usecase_test.dart`
Expected: FAIL — class undefined.

- [ ] **Step 3: Write minimal implementation**:

```dart
import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
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
      await reviews.saveReview(Review(
        rentalId: rental.id, userId: userId, userName: rental.userName,
        itemId: rental.itemId, itemName: rental.itemName,
        stars: stars, comment: clean, createdAt: DateTime.now(),
      ));
    } on RatingCountPending {
      rethrow;
    } catch (_) {
      throw const NetworkFailure('Could not save your rating. Please try again.');
    }
  }
}
```

`RatingCountPending` is defined in `firebase_review_data_source.dart` (Task 2) — import it there. (Mock never throws it; Firebase throws after retry exhaustion.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reviews/submit_review_usecase_test.dart`
Expected: PASS (4/4).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reviews/domain/usecases/submit_review_usecase.dart test/features/reviews/submit_review_usecase_test.dart
git commit -m "Add SubmitReviewUseCase with owner and completion guards"
```

### Task 5: ReviewViewModel + bottom sheet + widget test

**Files:**
- Create: `lib/features/reviews/presentation/viewmodels/review_viewmodel.dart`
- Create: `lib/features/reviews/presentation/widgets/review_bottom_sheet.dart`
- Test: `test/features/reviews/review_sheet_test.dart`

**Interfaces:**
- Consumes: `SubmitReviewUseCase`, `ReviewRepository`, `Rental`, `userId`.
- Produces: `ReviewViewModel{existing, loading, submitting, error, savedWithPendingCount, load(), submit(stars, comment)}`, `showReviewSheet({required BuildContext context, required Rental rental, required String userId})`.

- [ ] **Step 1: Write the failing test** (viewmodel-level; sheet covered in Step 3's widget test):

```dart
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/usecases/submit_review_usecase.dart';
import 'package:ferrer_rental_shop/features/reviews/presentation/viewmodels/review_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('submit stores review and clears error', () async {
    final repo = ReviewRepositoryImpl(MockReviewDataSource());
    final vm = ReviewViewModel(
      submit: SubmitReviewUseCase(repo), reviews: repo,
      rental: Rental(id: 'rx', userId: 'u1', userName: 'M', itemId: 'i1',
          itemName: 'G', startDate: DateTime(2026, 8, 1), endDate: DateTime(2026, 8, 5),
          rentalFee: 1, securityDeposit: 1, total: 2,
          status: 'completed', createdAt: DateTime(2026, 8, 1)),
      userId: 'u1',
    );
    await vm.submit(4, 'Nice');
    expect(vm.error, isNull);
    expect(vm.submitting, isFalse);
    expect((await repo.reviewForRentalStream('rx').first)?.stars, 4);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reviews/review_sheet_test.dart`
Expected: FAIL — class undefined.

- [ ] **Step 3: Write minimal implementation**

Viewmodel:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/firebase_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/usecases/submit_review_usecase.dart';

class ReviewViewModel extends ChangeNotifier {
  ReviewViewModel({required this.submit, required this.reviews,
    required this.rental, required this.userId}) {
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
      await submit.execute(rental: rental, userId: userId, stars: stars, comment: comment);
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
```

Sheet (`showReviewSheet`): `showModalBottomSheet` (rounded 28, cream `AppColors.cream`), `ChangeNotifierProvider` creating the VM from `context.read<SubmitReviewUseCase>()`, `context.read<ReviewRepository>()`, plus rental/userId args; stateful star row (5 `IconButton`s, filled `Icons.star_rounded` rose/gold vs `Icons.star_outline_rounded`), multiline comment field maxLength 500, Submit/Update `ElevatedButton` calling `vm.send`, popping `true` on success. On success the caller shows `TopSnackbar`: `savedWithPendingCount ? 'Rating saved, count updating shortly.' : 'Thanks for your feedback!'`. (Read `top_snackbar.dart` for exact show API before writing.)

Widget test addition in same file: pump `MaterialApp(home: Builder(... showReviewSheet ...))` with `Provider<SubmitReviewUseCase>` + `Provider<ReviewRepository>` (mock-backed), tap 4th star, enter comment, tap Submit, expect mock review stars == 4. (Write after VM passes; run together.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/reviews/review_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reviews/presentation test/features/reviews/review_sheet_test.dart
git commit -m "Add review bottom sheet and viewmodel"
```

### Task 6: Rental card pill + details row

**Files:**
- Modify: `lib/features/rentals/presentation/widgets/rental_card.dart` (else branch ~line 202)
- Modify: `lib/features/rentals/presentation/views/rental_details_screen.dart` (Returned section ~line 303)
- Modify: `lib/main.dart` (register `ReviewRepository` + `SubmitReviewUseCase` providers)

**Interfaces:**
- Consumes: `showReviewSheet`, `ReviewRepository.reviewForRentalStream`, `AuthRepository` (for uid — `MyRentalsScreen` already has user context; pass `userId` down or read `AuthRepository` via context; check what card callers have and use the same source).
- Produces: rated/unrated pill on completed cards; "Your rating" row in details.

- [ ] **Step 1: Write the failing test** — widget test `test/features/reviews/rate_pill_test.dart`: pump `RentalCard` (completed rental, mock `ReviewRepository` with no review) inside `Provider<ReviewRepository>` + required repos, expect text `Rate`; with seeded 5★ review expect `★ 5.0`. (Read `rental_card.dart` constructor + `my_rentals_screen.dart` card instantiation first to get required args.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reviews/rate_pill_test.dart`
Expected: FAIL — no `Rate` text found.

- [ ] **Step 3: Write minimal implementation**

`main.dart` providers (after the rental providers):

```dart
Provider<ReviewRepository>.value(
  value: ReviewRepositoryImpl(ReviewRepositoryImpl.defaultDataSource())),
Provider<SubmitReviewUseCase>(
  create: (ctx) => SubmitReviewUseCase(ctx.read<ReviewRepository>())),
```

Card: module-level `final Set<String> _pulseShown = {};` In the `else` branch, when `rental.isCompleted`, replace the plain "View Details" row with a `StreamBuilder<Review?>` on `context.read<ReviewRepository>().reviewForRentalStream(rental.id)`:
- data null → gold-outlined `Rate` pill (`Icons.star_outline_rounded`); pulse (`ScaleTransition` or `AnimatedContainer` elevation) only if `!_pulseShown.contains(rental.id)`, then add id.
- data present → filled pill `★ {stars}.0` opening the same sheet.
- Tapping opens `showReviewSheet(context: context, rental: rental, userId: <uid>)`.
- Keep "View Details" affordance: whole card already navigates; pill uses its own `GestureDetector` with `onTap` stopping at pill (wrap pill in `GestureDetector(behavior: HitTestBehavior.opaque)`).

Details screen: under the `Returned` row add a `ListTile`-style row: `existing == null ? 'Tap to rate your experience' : '★ {stars} · {comment or "No comment"}'`, wrapped in the same stream, opening the sheet. Reuse the pill's builder by extracting `RatePill(rentalId, rental, userId)` widget in the reviews feature and importing it in both places.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/reviews/rate_pill_test.dart`
Expected: PASS. Then: `flutter analyze` clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/rentals/presentation/widgets/rental_card.dart lib/features/rentals/presentation/views/rental_details_screen.dart lib/main.dart lib/features/reviews/presentation/widgets/rate_pill.dart test/features/reviews/rate_pill_test.dart
git commit -m "Wire rate pill into completed rentals and details"
```

### Task 7: Item header rating + admin feed

**Files:**
- Modify: `lib/features/item_details/presentation/views/item_details_screen.dart` (header) + viewmodel if it wraps repos (read both first; add `ratingSummaryStream` passthrough only if the VM owns repo access, else `context.read<ReviewRepository>()` directly in the view)
- Modify: `lib/features/admin/rental_management/presentation/views/rental_management_screen.dart` (completed tab tile: `★ n` + truncated comment via `FutureBuilder(await repo.reviewForRentalStream(id).first)`, read-only)

**Interfaces:**
- Consumes: `ReviewRepository.ratingSummaryStream/itemReviewsStream/reviewForRentalStream`.

- [ ] **Step 1: Write the failing test** — widget test `test/features/reviews/item_rating_test.dart`: pump the item header rating widget (extract `ItemRatingHeader(itemId)` in reviews widgets so it is testable standalone) with mock repo seeded 5★+4★ on that item; expect `★ 4.5 (2)`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reviews/item_rating_test.dart`
Expected: FAIL — widget undefined.

- [ ] **Step 3: Write minimal implementation**

`ItemRatingHeader(itemId)`: `StreamBuilder<RatingSummary>` → `★ {avg.toStringAsFixed(1)} ({count})`, empty → `No reviews yet`. Recent list `ItemReviewList(itemId)`: `StreamBuilder<List<Review>>` latest 5, rows (first name = `userName.split(' ').first`, stars, comment, date via `Formatters.date`); empty → `Be the first to review` hint. Insert header under the item title and the list below the description section. Admin completed tile: append `★ {stars}` + `comment` (max 1 line, ellipsis) under the existing subtitle; no buttons.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/reviews/item_rating_test.dart`
Expected: PASS. Then: `flutter analyze` clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/item_details lib/features/admin/rental_management lib/features/reviews/presentation/widgets/item_rating_widgets.dart test/features/reviews/item_rating_test.dart
git commit -m "Show item ratings and admin review feed"
```

### Task 8: Rules, indexes, full verification

**Files:**
- Modify: `firestore.rules` (reviews block + items aggregate allowance)
- Modify: `firestore.indexes.json` (read file first, mirror an existing entry's shape)
- Deploy (manual, needs console access — do NOT block on it)

**Interfaces:**
- Consumes: Task 2 field names.

- [ ] **Step 1: Append rules** — new block after rentals/appointments:

```
match /reviews/{rentalId} {
  allow read: if isSignedIn();
  allow create: if isSignedIn()
    && request.resource.data.userId == request.auth.uid
    && request.resource.data.stars is int
    && request.resource.data.stars >= 1
    && request.resource.data.stars <= 5
    && request.resource.data.comment is string
    && request.resource.data.comment.size() <= 500
    && exists(/databases/$(database)/documents/rentals/$(rentalId))
    && get(/databases/$(database)/documents/rentals/$(rentalId)).data.status == 'completed'
    && get(/databases/$(database)/documents/rentals/$(rentalId)).data.userId == request.auth.uid;
  allow update: if isSignedIn()
    && resource.data.userId == request.auth.uid
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['stars', 'comment', 'updatedAt'])
    && request.resource.data.stars is int
    && request.resource.data.stars >= 1
    && request.resource.data.stars <= 5;
  allow delete: if isAdmin();
}
```

Items: extend the existing update line to
`|| (isSignedIn() && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['avgRating', 'ratingCount']))`.
Trade-off (state in commit message body): any signed-in user can write aggregate fields — acceptable because values are recomputed from reviews, not trusted input.

- [ ] **Step 2: Append index** — `reviews(itemId ASC, createdAt DESC)`, mirroring the existing rentals/appointments entries' JSON shape.

- [ ] **Step 3: Verify everything**

Run: `flutter analyze`
Expected: No issues found.
Run: `flutter test`
Expected: All tests passed (previous 128 + new review tests).

- [ ] **Step 4: Commit**

```bash
git add firestore.rules firestore.indexes.json
git commit -m "Add review security rules and index"
```

Manual follow-up (not part of automation): `firebase deploy --only firestore:rules,firestore:indexes`, then console-check: customer rates a completed rental; second rating overwrites; pending rental write rejected; `avgRating` updates on items doc.
