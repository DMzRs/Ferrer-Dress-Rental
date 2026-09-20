import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/features/messaging/data/models/chat_message_model.dart';
import 'package:ferrer_rental_shop/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversation round-trips through fromMap', () {
    final m = ConversationModel.fromMap('u1', {
      'userId': 'u1',
      'userName': 'Maria',
      'lastText': 'Hi there',
      'lastSenderRole': 'admin',
      'updatedAt': DateTime(2026, 9, 20, 9, 0),
      'lastSeenCustomer': DateTime(2026, 9, 20, 8, 0),
    });
    expect(m.userId, 'u1');
    expect(m.unreadForCustomer, isTrue);
    final back = ConversationModel.fromEntity(m).toMap();
    expect(back['lastText'], 'Hi there');
  });

  test('conversation defaults missing fields safely', () {
    final m = ConversationModel.fromMap('u9', {'userId': 'u9'});
    expect(m.userName, '');
    expect(m.updatedAt, isNull);
    expect(m.unreadForCustomer, isFalse);
  });

  test('message toMap(forFirestore: true) encodes dates as Timestamp', () {
    final m = ChatMessageModel.fromEntity(const ChatMessageModel(
      id: 'm1',
      senderId: 'u1',
      senderRole: 'customer',
      text: 'Hello',
      createdAt: null,
    ));
    final map = m.toMap(forFirestore: true);
    expect(map['senderRole'], 'customer');
    expect(map['text'], 'Hello');
  });

  test('message fromMap parses Timestamp createdAt', () {
    final m = ChatMessageModel.fromMap('m2', {
      'senderId': 'shop',
      'senderRole': 'admin',
      'text': 'Hi Maria',
      'createdAt': Timestamp.fromDate(DateTime(2026, 9, 20, 9, 30)),
    });
    expect(m.createdAt, DateTime(2026, 9, 20, 9, 30));
    expect(m.isMine('u1'), isFalse);
  });
}
