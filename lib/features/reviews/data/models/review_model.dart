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
        rentalId: r.rentalId,
        userId: r.userId,
        userName: r.userName,
        itemId: r.itemId,
        itemName: r.itemName,
        stars: r.stars,
        comment: r.comment,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  Map<String, dynamic> toMap({bool forFirestore = false}) {
    dynamic encode(DateTime date) =>
        forFirestore ? Timestamp.fromDate(date) : date.toIso8601String();
    return {
      'userId': userId,
      'userName': userName,
      'itemId': itemId,
      'itemName': itemName,
      'stars': stars,
      'comment': comment,
      'createdAt': encode(createdAt),
      if (updatedAt != null) 'updatedAt': encode(updatedAt!),
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
