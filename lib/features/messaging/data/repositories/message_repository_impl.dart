import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/firebase_message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/mock_message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';

/// Delegates message operations to the configured data source.
class MessageRepositoryImpl implements MessageRepository {
  const MessageRepositoryImpl(this._dataSource);

  final MessageDataSource _dataSource;

  /// Picks the Firebase or mock message source from app config.
  static MessageDataSource defaultDataSource() {
    if (AppConfig.firebaseEnabled) return FirebaseMessageDataSource();
    return MockMessageDataSource();
  }

  /// Watches a single customer thread by user id.
  @override
  Stream<Conversation?> watchThread(String userId) =>
      _dataSource.watchThread(userId);

  /// Watches all threads ordered by most recent activity.
  @override
  Stream<List<Conversation>> watchInbox() => _dataSource.watchInbox();

  /// Watches newest-first messages for a thread with a page limit.
  @override
  Stream<List<ChatMessage>> watchMessages(String userId, {int limit = 50}) =>
      _dataSource.watchMessages(userId, limit: limit);

  /// Appends a message and refreshes the thread preview.
  @override
  Future<void> sendMessage({
    required String threadUserId,
    required String senderId,
    required String senderRole,
    required String text,
    String userName = '',
  }) =>
      _dataSource.sendMessage(
        threadUserId: threadUserId,
        senderId: senderId,
        senderRole: senderRole,
        text: text,
        userName: userName,
      );

  /// Marks a thread read for one side without write loops.
  @override
  Future<void> markSeen(String threadUserId, String role) =>
      _dataSource.markSeen(threadUserId, role);
}
