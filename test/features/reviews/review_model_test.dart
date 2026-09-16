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
