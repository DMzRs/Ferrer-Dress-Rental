import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/firebase_message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/mock_message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';

class MessageRepositoryImpl implements MessageRepository {
  const MessageRepositoryImpl(this._dataSource);

  final MessageDataSource _dataSource;

  static MessageDataSource defaultDataSource() {
    if (AppConfig.firebaseEnabled) return FirebaseMessageDataSource();
    return MockMessageDataSource();
  }

  @override
  Stream<Conversation?> watchThread(String userId) =>
      _dataSource.watchThread(userId);

  @override
  Stream<List<Conversation>> watchInbox() => _dataSource.watchInbox();

  @override
  Stream<List<ChatMessage>> watchMessages(String userId, {int limit = 50}) =>
      _dataSource.watchMessages(userId, limit: limit);

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

  @override
  Future<void> markSeen(String threadUserId, String role) =>
      _dataSource.markSeen(threadUserId, role);
}
