import 'package:ferrer_rental_shop/features/messaging/data/datasources/mock_message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('send creates thread, messages stream, markSeen clears unread', () async {
    final repo = MessageRepositoryImpl(MockMessageDataSource());
    await repo.sendMessage(
      threadUserId: 'u1',
      senderId: 'u1',
      senderRole: 'customer',
      userName: 'Maria',
      text: 'Is this gown available Saturday?',
    );
    final thread = await repo.watchThread('u1').first;
    expect(thread?.lastText, 'Is this gown available Saturday?');
    expect(thread?.unreadForAdmin, isTrue);
    final messages = await repo.watchMessages('u1').first;
    expect(messages.single.text, 'Is this gown available Saturday?');

    await repo.markSeen('u1', 'admin');
    final seen = await repo.watchThread('u1').first;
    expect(seen?.unreadForAdmin, isFalse);
    expect(seen?.userName, 'Maria');
  });

  test('admin reply flips unread to the customer side', () async {
    final repo = MessageRepositoryImpl(MockMessageDataSource());
    await repo.sendMessage(
      threadUserId: 'u1',
      senderId: 'u1',
      senderRole: 'customer',
      userName: 'Maria',
      text: 'Hi',
    );
    await repo.sendMessage(
      threadUserId: 'u1',
      senderId: 'admin-1',
      senderRole: 'admin',
      userName: 'Maria',
      text: 'Yes, it is!',
    );
    final thread = await repo.watchThread('u1').first;
    expect(thread?.unreadForCustomer, isTrue);
    expect(thread?.lastSenderRole, 'admin');
    final inbox = await repo.watchInbox().first;
    expect(inbox.single.userId, 'u1');
  });

  test('markSeen on missing thread is a no-op', () async {
    final repo = MessageRepositoryImpl(MockMessageDataSource());
    await repo.markSeen('ghost', 'customer');
    expect(await repo.watchThread('ghost').first, isNull);
    expect(await repo.watchInbox().first, isEmpty);
  });
}
