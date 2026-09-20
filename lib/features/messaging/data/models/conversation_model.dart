import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.userId,
    super.userName,
    super.lastText,
    super.lastSenderRole,
    super.updatedAt,
    super.lastSeenCustomer,
    super.lastSeenAdmin,
  });

  factory ConversationModel.fromMap(String docId, Map<String, dynamic> map) {
    return ConversationModel(
      userId: (map['userId'] ?? docId) as String,
      userName: (map['userName'] ?? '') as String,
      lastText: (map['lastText'] ?? '') as String,
      lastSenderRole: (map['lastSenderRole'] ?? '') as String,
      updatedAt:
          map['updatedAt'] == null ? null : _toDate(map['updatedAt']),
      lastSeenCustomer: map['lastSeenCustomer'] == null
          ? null
          : _toDate(map['lastSeenCustomer']),
      lastSeenAdmin: map['lastSeenAdmin'] == null
          ? null
          : _toDate(map['lastSeenAdmin']),
    );
  }

  factory ConversationModel.fromEntity(Conversation c) => ConversationModel(
        userId: c.userId,
        userName: c.userName,
        lastText: c.lastText,
        lastSenderRole: c.lastSenderRole,
        updatedAt: c.updatedAt,
        lastSeenCustomer: c.lastSeenCustomer,
        lastSeenAdmin: c.lastSeenAdmin,
      );

  Map<String, dynamic> toMap({bool forFirestore = false}) {
    dynamic encode(DateTime? date) {
      if (date == null) return null;
      return forFirestore ? Timestamp.fromDate(date) : date.toIso8601String();
    }

    return {
      'userId': userId,
      'userName': userName,
      'lastText': lastText,
      'lastSenderRole': lastSenderRole,
      if (updatedAt != null) 'updatedAt': encode(updatedAt),
      if (lastSeenCustomer != null)
        'lastSeenCustomer': encode(lastSeenCustomer),
      if (lastSeenAdmin != null) 'lastSeenAdmin': encode(lastSeenAdmin),
    };
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
