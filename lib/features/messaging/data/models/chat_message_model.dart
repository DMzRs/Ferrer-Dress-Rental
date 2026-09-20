import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderRole,
    required super.text,
    super.createdAt,
  });

  factory ChatMessageModel.fromMap(String docId, Map<String, dynamic> map) {
    return ChatMessageModel(
      id: docId,
      senderId: (map['senderId'] ?? '') as String,
      senderRole: (map['senderRole'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      createdAt:
          map['createdAt'] == null ? null : _toDate(map['createdAt']),
    );
  }

  factory ChatMessageModel.fromEntity(ChatMessage m) => ChatMessageModel(
        id: m.id,
        senderId: m.senderId,
        senderRole: m.senderRole,
        text: m.text,
        createdAt: m.createdAt,
      );

  Map<String, dynamic> toMap({bool forFirestore = false}) {
    dynamic encode(DateTime? date) {
      if (date == null) return null;
      return forFirestore ? Timestamp.fromDate(date) : date.toIso8601String();
    }

    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      if (createdAt != null) 'createdAt': encode(createdAt),
    };
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
