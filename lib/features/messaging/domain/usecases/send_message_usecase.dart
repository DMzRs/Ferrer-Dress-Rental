import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';

class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final MessageRepository _repository;

  Future<void> execute({
    required String threadUserId,
    required String senderId,
    required String senderRole,
    required String text,
    String userName = '',
  }) async {
    if (threadUserId.isEmpty || senderId.isEmpty) {
      throw const FormatException('Missing sender details.');
    }
    if (senderRole != 'customer' && senderRole != 'admin') {
      throw const FormatException('Unknown sender role.');
    }
    final clean = text.trim();
    if (clean.isEmpty) {
      throw const FormatException('Write a message first.');
    }
    if (clean.length > 1000) {
      throw const FormatException('Keep messages under 1000 characters.');
    }
    try {
      await _repository.sendMessage(
        threadUserId: threadUserId,
        senderId: senderId,
        senderRole: senderRole,
        text: clean,
        userName: userName,
      );
    } catch (_) {
      throw const NetworkFailure('Could not send. Please try again.');
    }
  }
}
