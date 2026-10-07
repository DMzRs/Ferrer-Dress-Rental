import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';

/// Contract for watching threads, sending messages, and marking them seen.
abstract class MessageRepository {
/// Watches a single customer thread by user id.
  Stream<Conversation?> watchThread(String userId);
/// Watches all threads ordered by most recent activity.
  Stream<List<Conversation>> watchInbox();
/// Watches newest-first messages for a thread with a page limit.
  Stream<List<ChatMessage>> watchMessages(String userId, {int limit = 50});
/// Appends a message and refreshes the thread preview.
  Future<void> sendMessage({
    required String threadUserId,
    required String senderId,
    required String senderRole,
    required String text,
    String userName = '',
  });
/// Marks a thread read for one side without write loops.
  Future<void> markSeen(String threadUserId, String role);
}
