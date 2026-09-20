import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ferrer_rental_shop/core/constants/firestore_collections.dart';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/models/chat_message_model.dart';
import 'package:ferrer_rental_shop/features/messaging/data/models/conversation_model.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';

class FirebaseMessageDataSource implements MessageDataSource {
  FirebaseFirestore get _db => AppFirestore.instance;

  DocumentReference<Map<String, dynamic>> _thread(String userId) =>
      _db.collection(FirestoreCollections.conversations).doc(userId);

  @override
  Stream<Conversation?> watchThread(String userId) {
    return _thread(userId).snapshots().map(
          (d) => d.exists ? ConversationModel.fromMap(d.id, d.data()!) : null,
        );
  }

  @override
  Stream<List<Conversation>> watchInbox() {
    return _db
        .collection(FirestoreCollections.conversations)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ConversationModel.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String userId, {int limit = 50}) {
    // Newest-first page; the UI reverses so latest sits at the bottom.
    return _thread(userId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ChatMessageModel.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> sendMessage({
    required String threadUserId,
    required String senderId,
    required String senderRole,
    required String text,
    String userName = '',
  }) async {
    final clean = text.trim();
    final threadRef = _thread(threadUserId);
    final existing = await threadRef.get();
    final batch = _db.batch();
    batch.set(
      threadRef.collection('messages').doc(),
      {
        'senderId': senderId,
        'senderRole': senderRole,
        'text': clean,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    final preview = <String, dynamic>{
      'lastText': clean.length > 120 ? clean.substring(0, 120) : clean,
      'lastSenderRole': senderRole,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) {
      preview['userId'] = threadUserId;
      preview['userName'] = userName;
    }
    batch.set(threadRef, preview, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Future<void> markSeen(String threadUserId, String role) async {
    final threadRef = _thread(threadUserId);
    final existing = await threadRef.get();
    if (!existing.exists) return;
    await threadRef.update({
      role == 'admin' ? 'lastSeenAdmin' : 'lastSeenCustomer':
          FieldValue.serverTimestamp(),
    });
  }
}
