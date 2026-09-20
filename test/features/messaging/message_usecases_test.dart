import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMessageRepository implements MessageRepository {
  int sends = 0;
  int seens = 0;
  bool throwOnSend = false;
  String lastText = '';

  @override
  Stream<Conversation?> watchThread(String userId) =>
      const Stream.empty();

  @override
  Stream<List<Conversation>> watchInbox() => const Stream.empty();

  @override
  Stream<List<ChatMessage>> watchMessages(String userId, {int limit = 50}) =>
      const Stream.empty();

  @override
  Future<void> sendMessage({
    required String threadUserId,
    required String senderId,
    required String senderRole,
    required String text,
    String userName = '',
  }) async {
    if (throwOnSend) throw Exception('db down');
    sends++;
    lastText = text;
  }

  @override
  Future<void> markSeen(String threadUserId, String role) async {
    seens++;
  }
}

void main() {
  test('sends trimmed text within limits', () async {
    final repo = FakeMessageRepository();
    final usecase = SendMessageUseCase(repo);
    await usecase.execute(
      threadUserId: 'u1',
      senderId: 'u1',
      senderRole: 'customer',
      text: '  Hello shop  ',
    );
    expect(repo.sends, 1);
    expect(repo.lastText, 'Hello shop');
  });

  test('rejects empty and overlong text', () {
    final usecase = SendMessageUseCase(FakeMessageRepository());
    expect(
      () => usecase.execute(
        threadUserId: 'u1',
        senderId: 'u1',
        senderRole: 'customer',
        text: '   ',
      ),
      throwsFormatException,
    );
    expect(
      () => usecase.execute(
        threadUserId: 'u1',
        senderId: 'u1',
        senderRole: 'customer',
        text: List.filled(1001, 'x').join(),
      ),
      throwsFormatException,
    );
  });

  test('rejects unknown sender role', () {
    final usecase = SendMessageUseCase(FakeMessageRepository());
    expect(
      () => usecase.execute(
        threadUserId: 'u1',
        senderId: 'u1',
        senderRole: 'staff',
        text: 'Hi',
      ),
      throwsFormatException,
    );
  });

  test('wraps IO errors in NetworkFailure', () {
    final repo = FakeMessageRepository()..throwOnSend = true;
    final usecase = SendMessageUseCase(repo);
    expect(
      () => usecase.execute(
        threadUserId: 'u1',
        senderId: 'u1',
        senderRole: 'customer',
        text: 'Hi',
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('markSeen delegates with role', () async {
    final repo = FakeMessageRepository();
    await MarkSeenUseCase(repo).execute('u1', 'admin');
    expect(repo.seens, 1);
  });
}
