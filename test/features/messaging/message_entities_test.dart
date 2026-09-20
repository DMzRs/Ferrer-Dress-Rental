import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unread flags compare updatedAt against each side lastSeen', () {
    final now = DateTime(2026, 9, 20, 10, 0);
    const c = Conversation(
      userId: 'u1',
      userName: 'Maria',
      lastText: 'Hi',
      lastSenderRole: 'admin',
      updatedAt: null,
      lastSeenCustomer: null,
      lastSeenAdmin: null,
    );
    // No timestamp yet means no messages yet: nothing can be unread.
    expect(c.unreadForCustomer, isFalse);
    expect(c.unreadForAdmin, isFalse);
    final withTime = Conversation(
      userId: c.userId,
      userName: c.userName,
      lastText: c.lastText,
      lastSenderRole: c.lastSenderRole,
      updatedAt: now,
      lastSeenCustomer: null,
      lastSeenAdmin: null,
    );
    expect(withTime.unreadForCustomer, isTrue);
    expect(withTime.unreadForAdmin, isFalse);
  });

  test('seen thread is not unread', () {
    final now = DateTime(2026, 9, 20, 10, 0);
    final c = Conversation(
      userId: 'u1',
      userName: 'Maria',
      lastText: 'Hi',
      lastSenderRole: 'admin',
      updatedAt: now,
      lastSeenCustomer: now,
      lastSeenAdmin: null,
    );
    expect(c.unreadForCustomer, isFalse);
    expect(c.unreadForAdmin, isFalse);
  });

  test('admin-sent message counts unread for admin only when customer replied', () {
    final now = DateTime(2026, 9, 20, 10, 0);
    final c = Conversation(
      userId: 'u1',
      userName: 'Maria',
      lastText: 'Thanks',
      lastSenderRole: 'customer',
      updatedAt: now,
      lastSeenCustomer: now,
      lastSeenAdmin: null,
    );
    expect(c.unreadForCustomer, isFalse);
    expect(c.unreadForAdmin, isTrue);
  });

  test('message ownership follows sender id', () {
    const m = ChatMessage(
      id: 'm1',
      senderId: 'u1',
      senderRole: 'customer',
      text: 'Hello',
      createdAt: null,
    );
    expect(m.isMine('u1'), isTrue);
    expect(m.isMine('other'), isFalse);
  });
}
