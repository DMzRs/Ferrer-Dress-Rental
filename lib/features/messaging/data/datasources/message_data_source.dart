import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';

abstract class MessageDataSource {
  Stream<Conversation?> watchThread(String userId);
  Stream<List<Conversation>> watchInbox();
  Stream<List<ChatMessage>> watchMessages(String userId, {int limit = 50});
  Future<void> sendMessage({
    required String threadUserId,
    required String senderId,
    required String senderRole,
    required String text,
    String userName = '',
  });
  Future<void> markSeen(String threadUserId, String role);
}
