import 'dart:async';

import 'package:ferrer_rental_shop/features/messaging/data/datasources/message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';

class MockMessageDataSource implements MessageDataSource {
  MockMessageDataSource();

  final Map<String, Conversation> _threads = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final StreamController<void> _threadTick =
      StreamController<void>.broadcast();
  final StreamController<void> _msgTick =
      StreamController<void>.broadcast();
  int _seq = 0;

  void _emitThreads() {
    if (!_threadTick.isClosed) _threadTick.add(null);
  }

  void _emitMessages() {
    if (!_msgTick.isClosed) _msgTick.add(null);
  }

  @override
  Stream<Conversation?> watchThread(String userId) async* {
    yield _threads[userId];
    await for (final _ in _threadTick.stream) {
      yield _threads[userId];
    }
  }

  @override
  Stream<List<Conversation>> watchInbox() async* {
    yield _inbox();
    await for (final _ in _threadTick.stream) {
      yield _inbox();
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String userId,
      {int limit = 50}) async* {
    yield _forThread(userId, limit);
    await for (final _ in _msgTick.stream) {
      yield _forThread(userId, limit);
    }
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
    final now = DateTime.now();
    final existing = _threads[threadUserId];
    _messages.putIfAbsent(threadUserId, () => []);
    _messages[threadUserId]!.add(ChatMessage(
      id: 'm${_seq++}',
      senderId: senderId,
      senderRole: senderRole,
      text: clean,
      createdAt: now,
    ));
    _threads[threadUserId] = Conversation(
      userId: threadUserId,
      userName: existing?.userName ?? userName,
      lastText: clean.length > 120 ? clean.substring(0, 120) : clean,
      lastSenderRole: senderRole,
      updatedAt: now,
      lastSeenCustomer: existing?.lastSeenCustomer,
      lastSeenAdmin: existing?.lastSeenAdmin,
    );
    _emitThreads();
    _emitMessages();
  }

  @override
  Future<void> markSeen(String threadUserId, String role) async {
    final existing = _threads[threadUserId];
    if (existing == null) return;
    _threads[threadUserId] = Conversation(
      userId: existing.userId,
      userName: existing.userName,
      lastText: existing.lastText,
      lastSenderRole: existing.lastSenderRole,
      updatedAt: existing.updatedAt,
      lastSeenCustomer:
          role == 'admin' ? existing.lastSeenCustomer : DateTime.now(),
      lastSeenAdmin:
          role == 'admin' ? DateTime.now() : existing.lastSeenAdmin,
    );
    _emitThreads();
  }

  List<Conversation> _inbox() {
    final list = _threads.values.toList()
      ..sort((a, b) {
        final at = a.updatedAt;
        final bt = b.updatedAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
    return list;
  }

  List<ChatMessage> _forThread(String userId, int limit) {
    final list = [...?_messages[userId]];
    list.sort((a, b) {
      final at = a.createdAt;
      final bt = b.createdAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return list.take(limit).toList();
  }
}
