import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';

class ThreadViewModel extends ChangeNotifier {
  ThreadViewModel({
    required this.messages,
    required this.sender,
    required this.seen,
    required this.auth,
    this.initialLimit = 50,
    this.autoMarkRead = false,
  }) {
    _limit = initialLimit;
    _authSub = auth.authStateChanges.listen((user) {
      _userId = user?.uid;
      _userName = user?.fullName ?? '';
      _isAdmin = user?.isAdmin ?? false;
      _resubscribe();
    });
  }

  final MessageRepository messages;
  final SendMessageUseCase sender;
  final MarkSeenUseCase seen;
  final AuthRepository auth;
  final int initialLimit;

  /// When true, every incoming batch auto-marks read. Only for views that
  /// are visible by construction (admin pushed thread route). Tab screens
  /// (IndexedStack builds all tabs eagerly) must leave this false and call
  /// [markRead] explicitly when the user opens the tab — otherwise merely
  /// launching the app would clear all unread state.
  final bool autoMarkRead;

  StreamSubscription? _authSub;
  StreamSubscription<List<ChatMessage>>? _messageSub;
  StreamSubscription<Conversation?>? _threadSub;
  String? _userId;
  String _userName = '';
  bool _isAdmin = false;
  Conversation? _thread;
  late int _limit;
  bool _sending = false;
  String? _error;
  String? _threadUserId;

  /// The customer thread always belongs to the signed-in user; the admin
  /// thread view sets an explicit target via [openThread].
  List<ChatMessage> _messages = const [];
  List<ChatMessage> get messageList => _messages;
  bool get sending => _sending;
  String? get error => _error;
  bool get canLoadEarlier => _messages.length >= _limit;

  String? get threadUserId => _threadUserId ?? _userId;
  String? get currentUid => _userId;

  void openThread(String userId) {
    _threadUserId = userId;
    _limit = initialLimit;
    _resubscribe();
  }

  void loadEarlier() {
    _limit += 50;
    _resubscribe();
    notifyListeners();
  }

  Future<bool> send(String text) async {
    final uid = _userId;
    final target = threadUserId;
    if (uid == null || target == null) {
      _error = 'Sign in to send messages.';
      notifyListeners();
      return false;
    }
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      await sender.execute(
        threadUserId: target,
        senderId: uid,
        senderRole: _isAdmin ? 'admin' : 'customer',
        text: text,
        userName: _userName,
      );
      return true;
    } on FormatException catch (e) {
      _error = e.message;
      return false;
    } on Failure catch (e) {
      _error = e.message;
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> markRead() async {
    // Guarded: only write when something from the other side is actually
    // unread. Without this, every stream emission would rewrite lastSeen
    // forever (each write re-emits → another write → infinite loop).
    final target = threadUserId;
    if (target == null) return;
    final other = _isAdmin ? 'customer' : 'admin';
    final seenStamp =
        _isAdmin ? _thread?.lastSeenAdmin : _thread?.lastSeenCustomer;
    final hasUnread = _messages.any((m) =>
        m.senderRole == other &&
        m.createdAt != null &&
        (seenStamp == null || m.createdAt!.isAfter(seenStamp)));
    if (!hasUnread) return;
    try {
      await seen.execute(target, _isAdmin ? 'admin' : 'customer');
    } catch (_) {
      // Read markers are best-effort; never block the thread.
    }
  }

  void _resubscribe() {
    _messageSub?.cancel();
    _threadSub?.cancel();
    final target = threadUserId;
    if (target == null) return;
    _messageSub = messages
        .watchMessages(target, limit: _limit)
        .listen(_onMessages);
    _threadSub = messages.watchThread(target).listen((thread) {
      _thread = thread;
      notifyListeners();
    });
  }

  void _onMessages(List<ChatMessage> incoming) {
    _messages = incoming;
    notifyListeners();
    if (autoMarkRead) markRead();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _messageSub?.cancel();
    _threadSub?.cancel();
    super.dispose();
  }
}
