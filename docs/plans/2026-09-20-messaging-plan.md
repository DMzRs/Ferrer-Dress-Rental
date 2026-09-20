# Messaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In-app text chat between each customer and the shop, on both apps, with unread bubbles.

**Architecture:** New `lib/features/messaging/` feature mirroring the reviews split (entity → model → Firebase+Mock datasource → repository → use cases → viewmodels → views). One thread per customer (`conversations/{userId}` + `messages` subcollection). Customer gets a thread screen as a 6th nav tab; admin gets an inbox + thread as a 7th tab. Shared `ThreadView` widget serves both.

**Tech Stack:** Flutter 3.47 / Dart 3.13, cloud_firestore, provider (ChangeNotifier), flutter_test.

**Spec:** `docs/specs/2026-09-20-messaging-design.md` — read it before starting; on any conflict the spec wins.

## Global Constraints

- Null-safety, `flutter analyze` clean, full `flutter test` green before each commit.
- Follow existing file patterns exactly (`RentalModel` parsing helpers with `_toDate`/`encode(forFirestore)`, `*RepositoryImpl.defaultDataSource()` via `AppConfig.firebaseEnabled`, `FormatException` for guard violations, `NetworkFailure` for IO errors).
- Commit after every task (`git add <task files>`, message per task).
- Never break existing test fakes: do NOT add abstract methods to `RentalRepository`, `AppointmentRepository`, `InventoryRepository`, or `AuthRepository`.
- `docs/superpowers/` is gitignored scratch — plan/spec live under `docs/`.
- Copy rules: boutique voice, no emojis in UI, Title Case for headers/buttons, sentence case for body, periods on full-sentence hints/errors.
- No emojis anywhere in UI strings.

---

### Task 1: Message entities

**Files:**
- Create: `lib/features/messaging/domain/entities/conversation.dart`
- Create: `lib/features/messaging/domain/entities/chat_message.dart`
- Test: `test/features/messaging/message_entities_test.dart`

**Interfaces:**
- Consumes: nothing (greenfield).
- Produces: `Conversation` (userId, userName, lastText, lastSenderRole, updatedAt, lastSeenCustomer, lastSeenAdmin, `unreadForCustomer`, `unreadForAdmin`), `ChatMessage` (id, senderId, senderRole, text, createdAt, `isMine(String uid)`).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unread flags compare updatedAt against each side lastSeen', () {
    const c = Conversation(
      userId: 'u1',
      userName: 'Maria',
      lastText: 'Hi',
      lastSenderRole: 'admin',
      updatedAt: null,
      lastSeenCustomer: null,
      lastSeenAdmin: null,
    );
    expect(c.unreadForCustomer, isTrue);
    expect(c.unreadForAdmin, isFalse);
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/messaging/message_entities_test.dart`
Expected: FAIL — file not found / class undefined.

- [ ] **Step 3: Write minimal implementation**

```dart
class Conversation {
  final String userId;
  final String userName;
  final String lastText;
  final String lastSenderRole;
  final DateTime? updatedAt;
  final DateTime? lastSeenCustomer;
  final DateTime? lastSeenAdmin;

  const Conversation({
    required this.userId,
    this.userName = '',
    this.lastText = '',
    this.lastSenderRole = '',
    this.updatedAt,
    this.lastSeenCustomer,
    this.lastSeenAdmin,
  });

  /// Unread for the customer: shop wrote last and it is newer than the
  /// customer's last open (null seen-stamp counts as unread).
  bool get unreadForCustomer {
    if (lastSenderRole != 'admin' || updatedAt == null) return false;
    final seen = lastSeenCustomer;
    if (seen == null) return true;
    return updatedAt!.isAfter(seen);
  }

  /// Unread for admin: customer wrote last and it is newer than last open.
  bool get unreadForAdmin {
    if (lastSenderRole != 'customer' || updatedAt == null) return false;
    final seen = lastSeenAdmin;
    if (seen == null) return true;
    return updatedAt!.isAfter(seen);
  }
}
```

```dart
class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.createdAt,
  });

  bool isMine(String uid) => senderId == uid;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/messaging/message_entities_test.dart`
Expected: PASS (4/4).

- [ ] **Step 5: Commit**

```bash
git add lib/features/messaging/domain/entities test/features/messaging/message_entities_test.dart
git commit -m "Add messaging entities with unread math"
```

### Task 2: Message models

**Files:**
- Create: `lib/features/messaging/data/models/conversation_model.dart`
- Create: `lib/features/messaging/data/models/chat_message_model.dart`
- Test: `test/features/messaging/message_models_test.dart`

**Interfaces:**
- Consumes: `Conversation`, `ChatMessage` (Task 1).
- Produces: `ConversationModel.fromMap(docId, map)/fromEntity/toMap({forFirestore})`, `ChatMessageModel.fromMap(docId, map)/fromEntity/toMap({forFirestore})`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/features/messaging/data/models/chat_message_model.dart';
import 'package:ferrer_rental_shop/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversation round-trips through fromMap', () {
    final m = ConversationModel.fromMap('u1', {
      'userId': 'u1',
      'userName': 'Maria',
      'lastText': 'Hi there',
      'lastSenderRole': 'admin',
      'updatedAt': DateTime(2026, 9, 20, 9, 0),
      'lastSeenCustomer': DateTime(2026, 9, 20, 8, 0),
    });
    expect(m.userId, 'u1');
    expect(m.unreadForCustomer, isTrue);
    final back = ConversationModel.fromEntity(m).toMap();
    expect(back['lastText'], 'Hi there');
  });

  test('conversation defaults missing fields safely', () {
    final m = ConversationModel.fromMap('u9', {'userId': 'u9'});
    expect(m.userName, '');
    expect(m.updatedAt, isNull);
    expect(m.unreadForCustomer, isFalse);
  });

  test('message toMap(forFirestore: true) encodes dates as Timestamp', () {
    final m = ChatMessageModel.fromEntity(const ChatMessageModel(
      id: 'm1',
      senderId: 'u1',
      senderRole: 'customer',
      text: 'Hello',
      createdAt: null,
    ));
    final map = m.toMap(forFirestore: true);
    expect(map['senderRole'], 'customer');
    expect(map['text'], 'Hello');
  });

  test('message fromMap parses Timestamp createdAt', () {
    final m = ChatMessageModel.fromMap('m2', {
      'senderId': 'shop',
      'senderRole': 'admin',
      'text': 'Hi Maria',
      'createdAt': Timestamp.fromDate(DateTime(2026, 9, 20, 9, 30)),
    });
    expect(m.createdAt, DateTime(2026, 9, 20, 9, 30));
    expect(m.isMine('u1'), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/messaging/message_models_test.dart`
Expected: FAIL — classes undefined.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.userId,
    super.userName,
    super.lastText,
    super.lastSenderRole,
    super.updatedAt,
    super.lastSeenCustomer,
    super.lastSeenAdmin,
  });

  factory ConversationModel.fromMap(String docId, Map<String, dynamic> map) {
    return ConversationModel(
      userId: (map['userId'] ?? docId) as String,
      userName: (map['userName'] ?? '') as String,
      lastText: (map['lastText'] ?? '') as String,
      lastSenderRole: (map['lastSenderRole'] ?? '') as String,
      updatedAt:
          map['updatedAt'] == null ? null : _toDate(map['updatedAt']),
      lastSeenCustomer: map['lastSeenCustomer'] == null
          ? null
          : _toDate(map['lastSeenCustomer']),
      lastSeenAdmin: map['lastSeenAdmin'] == null
          ? null
          : _toDate(map['lastSeenAdmin']),
    );
  }

  factory ConversationModel.fromEntity(Conversation c) => ConversationModel(
        userId: c.userId,
        userName: c.userName,
        lastText: c.lastText,
        lastSenderRole: c.lastSenderRole,
        updatedAt: c.updatedAt,
        lastSeenCustomer: c.lastSeenCustomer,
        lastSeenAdmin: c.lastSeenAdmin,
      );

  Map<String, dynamic> toMap({bool forFirestore = false}) {
    dynamic encode(DateTime? date) {
      if (date == null) return null;
      return forFirestore ? Timestamp.fromDate(date) : date.toIso8601String();
    }

    return {
      'userId': userId,
      'userName': userName,
      'lastText': lastText,
      'lastSenderRole': lastSenderRole,
      if (updatedAt != null) 'updatedAt': encode(updatedAt),
      if (lastSeenCustomer != null)
        'lastSeenCustomer': encode(lastSeenCustomer),
      if (lastSeenAdmin != null) 'lastSeenAdmin': encode(lastSeenAdmin),
    };
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
```

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderRole,
    required super.text,
    super.createdAt,
  });

  factory ChatMessageModel.fromMap(String docId, Map<String, dynamic> map) {
    return ChatMessageModel(
      id: docId,
      senderId: (map['senderId'] ?? '') as String,
      senderRole: (map['senderRole'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      createdAt:
          map['createdAt'] == null ? null : _toDate(map['createdAt']),
    );
  }

  factory ChatMessageModel.fromEntity(ChatMessage m) => ChatMessageModel(
        id: m.id,
        senderId: m.senderId,
        senderRole: m.senderRole,
        text: m.text,
        createdAt: m.createdAt,
      );

  Map<String, dynamic> toMap({bool forFirestore = false}) {
    dynamic encode(DateTime? date) {
      if (date == null) return null;
      return forFirestore ? Timestamp.fromDate(date) : date.toIso8601String();
    }

    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      if (createdAt != null) 'createdAt': encode(createdAt),
    };
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/messaging/message_models_test.dart`
Expected: PASS (4/4).

- [ ] **Step 5: Commit**

```bash
git add lib/features/messaging/data/models test/features/messaging/message_models_test.dart
git commit -m "Add messaging models with Firestore mapping"
```

### Task 3: Collection constant, security rules, indexes

**Files:**
- Modify: `lib/core/constants/firestore_collections.dart` (add `conversations`)
- Modify: `firestore.rules` (append conversations + messages blocks before final `}` — anchor on the reviews block close)
- Modify: `firestore.indexes.json` (append conversations index mirroring existing entries)
- Test: none (rules verified by deploy + manual console check in Step 4)

**Interfaces:**
- Consumes: field names from Tasks 1–2.
- Produces: deployed rules + index; `FirestoreCollections.conversations`.

- [ ] **Step 1: Add the collection constant**

In `lib/core/constants/firestore_collections.dart` (class with `static const users/items/itemPhotos/rentals/appointments/reviews`), append:
```dart
  static const conversations = 'conversations';
```

- [ ] **Step 2: Append the rules block**

Append inside `match /databases/{database}/documents`, after the reviews block close:

```
    // ------------------------------------------------------------------
    // conversations (one thread per customer, id = userId)
    // ------------------------------------------------------------------
    match /conversations/{userId} {
      allow read: if isOwner(userId) || isAdmin();

      allow create, update: if isAdmin()
        || (isOwner(userId)
            && request.resource.data.userId == request.auth.uid
            && request.resource.data.diff(resource.data)
                  .affectedKeys().hasOnly([
                    'userId', 'userName', 'lastText', 'lastSenderRole',
                    'updatedAt', 'lastSeenCustomer',
                  ]));

      allow delete: if isAdmin();
    }

    match /conversations/{userId}/messages/{messageId} {
      allow read: if isAdmin()
        || (isSignedIn() && request.auth.uid == userId);

      allow create: if isSignedIn()
        && request.auth.uid == userId
        && request.resource.data.senderId == request.auth.uid
        && (request.resource.data.senderRole == 'customer'
            || request.resource.data.senderRole == 'admin')
        && ((request.auth.uid == userId
                && request.resource.data.senderRole == 'customer')
            || (isAdmin()
                && request.resource.data.senderRole == 'admin'))
        && request.resource.data.text is string
        && request.resource.data.text.size() >= 1
        && request.resource.data.text.size() <= 1000;

      allow update, delete: if isAdmin();
    }
```

Note: `create` on a missing doc — `resource` is null so `diff()` throws; split into two allowances to stay safe:
```
      allow create: if isAdmin()
        || (isOwner(userId)
            && request.resource.data.userId == request.auth.uid
            && request.resource.data.keys()
                  .hasOnly([
                    'userId', 'userName', 'lastText', 'lastSenderRole',
                    'updatedAt', 'lastSeenCustomer', 'lastSeenAdmin',
                  ]));

      allow update: if isAdmin()
        || (isOwner(userId)
            && request.resource.data.userId == request.auth.uid
            && request.resource.data.diff(resource.data)
                  .affectedKeys().hasOnly([
                    'lastText', 'lastSenderRole', 'updatedAt',
                    'lastSeenCustomer',
                  ]));
```
Use this split version (not the combined one above). Customer updates may never touch `userId`, `userName`, or `lastSeenAdmin`; only admins write `lastSeenAdmin`.

- [ ] **Step 3: Append the index**

In `firestore.indexes.json`, mirror an existing entry exactly:
```json
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    }
```
(Message queries are single-thread `orderBy('createdAt')` — no composite index needed.)

- [ ] **Step 4: Deploy and verify (manual, needs console access)**

Run: `firebase deploy --only firestore:rules,firestore:indexes`
Expected: `✔ rules file firestore.rules compiled successfully`, `✔ deployed indexes ... successfully`, `Deploy complete!`
Then console-check: as a test customer, write a thread doc (should succeed own / fail other's); send over-long text (must reject).

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/firestore_collections.dart firestore.rules firestore.indexes.json
git commit -m "Add messaging security rules and index"
```

### Task 4: Datasources, repository, streams

**Files:**
- Create: `lib/features/messaging/data/datasources/message_data_source.dart`
- Create: `lib/features/messaging/data/datasources/firebase_message_data_source.dart`
- Create: `lib/features/messaging/data/datasources/mock_message_data_source.dart`
- Create: `lib/features/messaging/domain/repositories/message_repository.dart`
- Create: `lib/features/messaging/data/repositories/message_repository_impl.dart`
- Test: `test/features/messaging/message_repository_test.dart`

**Interfaces:**
- Consumes: models (Task 2), `FirestoreCollections.conversations` (Task 3), `AppFirestore.instance`, `AppConfig.firebaseEnabled`.
- Produces: `MessageRepository{watchThread(userId), watchInbox(), watchMessages(userId, {limit}), sendMessage(...), markSeen(userId, role)}`, `MessageRepositoryImpl.defaultDataSource()`.

- [ ] **Step 1: Write the failing test** (mock-backed, exercises send → thread → messages → markSeen → unread math)

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/messaging/message_repository_test.dart`
Expected: FAIL — types undefined.

- [ ] **Step 3: Write minimal implementation**

`domain/repositories/message_repository.dart`:
```dart
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';

abstract class MessageRepository {
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
```

`data/datasources/message_data_source.dart`: identical signatures.

`data/repositories/message_repository_impl.dart` (mirror `RentalRepositoryImpl`: const ctor, `defaultDataSource()` switching on `AppConfig.firebaseEnabled`, pure delegation):
```dart
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
```

`firebase_message_data_source.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/core/constants/firestore_collections.dart';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/models/chat_message_model.dart';
import 'package:ferrer_rental_shop/features/messaging/data/models/conversation_model.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';

class FirebaseMessageDataSource implements MessageDataSource {
  FirebaseFirestore get _db => AppFirestore.instance;

  DocumentReference<Map<String, dynamic>> _thread(String userId) =>
      _db.collection(FirestoreCollections.conversations).doc(userId);

  @override
  Stream<Conversation?> watchThread(String userId) {
    return _thread(userId).snapshots().map(
          (d) => d.exists ? ConversationModel.fromMap(d.id, d.data()!) : null,
        );
  }

  @override
  Stream<List<Conversation>> watchInbox() {
    return _db
        .collection(FirestoreCollections.conversations)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ConversationModel.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String userId, {int limit = 50}) {
    // Newest-first page; the UI reverses so latest sits at the bottom.
    return _thread(userId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ChatMessageModel.fromMap(d.id, d.data())).toList());
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
    final threadRef = _thread(threadUserId);
    final existing = await threadRef.get();
    final batch = _db.batch();
    batch.set(
      threadRef.collection('messages').doc(),
      {
        'senderId': senderId,
        'senderRole': senderRole,
        'text': clean,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    final preview = <String, dynamic>{
      'lastText': clean.length > 120 ? clean.substring(0, 120) : clean,
      'lastSenderRole': senderRole,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) {
      preview['userId'] = threadUserId;
      preview['userName'] = userName;
    }
    batch.set(threadRef, preview, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Future<void> markSeen(String threadUserId, String role) async {
    final threadRef = _thread(threadUserId);
    final existing = await threadRef.get();
    if (!existing.exists) return;
    await threadRef.update({
      role == 'admin' ? 'lastSeenAdmin' : 'lastSeenCustomer':
          FieldValue.serverTimestamp(),
    });
  }
}
```

`mock_message_data_source.dart` (in-memory threads + per-thread broadcast; seed empty — tests seed via `sendMessage`):
```dart
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
```

DELETE the stray `saveReviewNoop` method above before saving (it is not part of the interface — leaving it would still compile since extra public methods are allowed, but it is cruft; do not include it).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/messaging/message_repository_test.dart`
Expected: PASS (3/3).

- [ ] **Step 5: Commit**

```bash
git add lib/features/messaging/data lib/features/messaging/domain/repositories test/features/messaging/message_repository_test.dart
git commit -m "Add messaging repository with Firebase and mock datasources"
```

### Task 5: Send + seen use cases

**Files:**
- Create: `lib/features/messaging/domain/usecases/send_message_usecase.dart`
- Create: `lib/features/messaging/domain/usecases/mark_seen_usecase.dart`
- Test: `test/features/messaging/message_usecases_test.dart`

**Interfaces:**
- Consumes: `MessageRepository` (Task 4).
- Produces: `SendMessageUseCase.execute({required String threadUserId, required String senderId, required String senderRole, required String text, String userName = ''})`, `MarkSeenUseCase.execute(threadUserId, role)`.

- [ ] **Step 1: Write the failing test** (fake repo recording calls)

```dart
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
    expect(repo.lastText, '  Hello shop  ');
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

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/messaging/message_usecases_test.dart`
Expected: FAIL — classes undefined.

- [ ] **Step 3: Write minimal implementation**

```dart
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
```

```dart
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';

class MarkSeenUseCase {
  const MarkSeenUseCase(this._repository);

  final MessageRepository _repository;

  Future<void> execute(String threadUserId, String role) =>
      _repository.markSeen(threadUserId, role);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/messaging/message_usecases_test.dart`
Expected: PASS (5/5).

- [ ] **Step 5: Commit**

```bash
git add lib/features/messaging/domain/usecases test/features/messaging/message_usecases_test.dart
git commit -m "Add messaging send and seen use cases"
```

### Task 6: Shared thread view + customer screen

**Files:**
- Create: `lib/features/messaging/presentation/widgets/thread_view.dart`
- Create: `lib/features/messaging/presentation/views/customer_thread_screen.dart`
- Create: `lib/features/messaging/presentation/viewmodels/thread_viewmodel.dart`
- Test: `test/features/messaging/thread_view_test.dart`

**Interfaces:**
- Consumes: `MessageRepository`, `SendMessageUseCase`, `MarkSeenUseCase` (Tasks 4–5), `AuthRepository` (uid + fullName via `authStateChanges`, same pattern as `MyRentalsViewModel`), `Formatters.timeAgo`.
- Produces: `ThreadViewModel{messages, sending, error, send(text), loadEarlier()}`, `ThreadView(threadUserId, title, isAdminView)`, `CustomerThreadScreen()`.

- [ ] **Step 1: Write the failing test**

- Produces: `ThreadViewModel{messages, sending, error, currentUid, messageList, canLoadEarlier, send(text), loadEarlier(), openThread(userId), markRead()}`, `ThreadView(otherLabel:, emptyText:)`, `CustomerThreadScreen()`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/mock_message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/viewmodels/thread_viewmodel.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/views/customer_thread_screen.dart';
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _customer = AppUser(
  uid: 'u1',
  fullName: 'Maria Santos',
  email: 'maria@example.com',
  phone: '09171234567',
  role: UserRole.customer,
);

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_customer);

  @override
  Future<Result<AppUser>> signIn(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signUp(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendSignInLink(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signInWithEmailLink(
          {required String email,
          required String link,
          String? fullName,
          String? phone,
          String? password}) =>
      throw UnimplementedError();

  @override
  Stream<String> emailLinkStream() => Stream<String>.empty();

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<void>> updateProfile(
          {String? fullName,
          String? phone,
          String? address,
          List<String>? savedPlaces}) =>
      throw UnimplementedError();

  @override
  Stream<int> usersCountStream() => Stream<int>.empty();
}

void main() {
  testWidgets('shows seeded shop message and sends a reply', (t) async {
    final repo = MessageRepositoryImpl(MockMessageDataSource());
    await repo.sendMessage(
      threadUserId: 'u1',
      senderId: 'admin-1',
      senderRole: 'admin',
      userName: 'Maria Santos',
      text: 'Hello Maria',
    );
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: FakeAuthRepository()),
          ChangeNotifierProvider<AuthViewModel>(
            create: (c) => AuthViewModel(c.read<AuthRepository>()),
          ),
          Provider<MessageRepository>.value(value: repo),
          Provider<SendMessageUseCase>(
            create: (c) => SendMessageUseCase(c.read<MessageRepository>()),
          ),
          Provider<MarkSeenUseCase>(
            create: (c) => MarkSeenUseCase(c.read<MessageRepository>()),
          ),
          ChangeNotifierProvider<ThreadViewModel>(
            create: (c) => ThreadViewModel(
              messages: c.read<MessageRepository>(),
              sender: c.read<SendMessageUseCase>(),
              seen: c.read<MarkSeenUseCase>(),
              auth: c.read<AuthRepository>(),
            ),
          ),
        ],
        child: const MaterialApp(home: CustomerThreadScreen()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Hello Maria'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Thanks!');
    await t.tap(find.byIcon(Icons.send_rounded));
    await t.pumpAndSettle();
    expect(find.text('Thanks!'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/messaging/thread_view_test.dart`
Expected: FAIL — classes undefined.

- [ ] **Step 3: Write minimal implementation**

`thread_viewmodel.dart` (mirrors `MyRentalsViewModel` auth-subscription shape):
```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

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
    } catch (_) {
      _error = 'Could not send. Please try again.';
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
    final seen =
        _isAdmin ? _thread?.lastSeenAdmin : _thread?.lastSeenCustomer;
    final hasUnread = _messages.any((m) =>
        m.senderRole == other &&
        m.createdAt != null &&
        (seen == null || m.createdAt!.isAfter(seen)));
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
    markRead();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _messageSub?.cancel();
    _threadSub?.cancel();
    super.dispose();
  }
}
```

```

`thread_view.dart` — shared list + composer (write it exactly):

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/viewmodels/thread_viewmodel.dart';

bool _isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Shared message list + composer. [otherLabel] captions the other side's
/// bubbles ("Ferrer Shop" for customers, customer first name for admins).
/// [emptyText] shows when the thread has no messages yet.
class ThreadView extends StatefulWidget {
  final String otherLabel;
  final String emptyText;

  const ThreadView({
    super.key,
    required this.otherLabel,
    this.emptyText = 'No messages yet. Say hello!',
  });

  @override
  State<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<ThreadView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ThreadViewModel>();
    // Stream yields newest-first; reverse:true pins the newest (index 0)
    // to the bottom. The Load-earlier button is the last builder item,
    // which renders at the top under reverse.
    final messages = vm.messageList;
    final itemCount =
        messages.length + (vm.canLoadEarlier ? 1 : 0);
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    widget.emptyText,
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 14, height: 1.5),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index >= messages.length) {
                      return Center(
                        child: TextButton(
                          onPressed: vm.loadEarlier,
                          child: const Text('Load earlier messages'),
                        ),
                      );
                    }
                    final message = messages[index];
                    final newer = index == 0
                        ? null
                        : messages[index - 1];
                    final showDate = newer == null ||
                        !_isSameDay(
                            newer.createdAt, message.createdAt);
                    return Column(
                      crossAxisAlignment: message.isMine(vm.currentUid ?? '')
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (showDate && message.createdAt != null)
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                Formatters.date(message.createdAt!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        _Bubble(
                          message: message,
                          mine: message.isMine(vm.currentUid ?? ''),
                          otherLabel: widget.otherLabel,
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
        ),
        if (vm.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Text(
              vm.error!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: 1000,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  enabled: !vm.sending,
                  decoration: const InputDecoration(
                    hintText: 'Write a message',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _send(vm),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                key: const ValueKey('send-message'),
                icon: const Icon(Icons.send_rounded),
                color: AppColors.roseDark,
                onPressed:
                    vm.sending ? null : () => _send(vm),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _send(ThreadViewModel vm) async {
    final ok = await vm.send(_controller.text);
    if (ok) _controller.clear();
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final String otherLabel;

  const _Bubble({
    required this.message,
    required this.mine,
    required this.otherLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? AppColors.roseDark : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 4),
          bottomRight: Radius.circular(mine ? 4 : 18),
        ),
        border: mine
            ? null
            : Border.all(color: AppColors.champagne),
      ),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                otherLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
          Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: mine ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.createdAt == null
                ? 'Sending…'
                : Formatters.timeAgo(message.createdAt!),
            style: TextStyle(
              fontSize: 10,
              color: (mine ? Colors.white : AppColors.inkSoft)
                  .withValues(alpha: .75),
            ),
          ),
        ],
      ),
    );
  }
}
```

`customer_thread_screen.dart` (const-constructible — no required params; the VM resolves the uid from auth):

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/viewmodels/thread_viewmodel.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/widgets/thread_view.dart';

class CustomerThreadScreen extends StatelessWidget {
  const CustomerThreadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThreadViewModel>(
      create: (_) => ThreadViewModel(
        messages: context.read<MessageRepository>(),
        sender: context.read<SendMessageUseCase>(),
        seen: context.read<MarkSeenUseCase>(),
        auth: context.read<AuthRepository>(),
      ),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.creamGradient),
        child: const SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(
                  'Messages',
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
              ),
              Expanded(
                child: ThreadView(otherLabel: 'Ferrer Shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`markRead` fires from VM `_onMessages` automatically on every batch — covers "opening stamps seen" without screen code.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/messaging/thread_view_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/messaging/presentation test/features/messaging/thread_view_test.dart
git commit -m "Add messaging thread view and customer screen"
```

### Task 7: Admin inbox + thread screen

**Files:**
- Create: `lib/features/messaging/presentation/views/admin_inbox_screen.dart`
- Create: `lib/features/messaging/presentation/views/admin_thread_screen.dart`
- Test: `test/features/messaging/admin_inbox_test.dart`

**Interfaces:**
- Consumes: `MessageRepository`, `ThreadView` + `ThreadViewModel` (Task 6), `Formatters.timeAgo`.
- Produces: `AdminInboxScreen()` (const, reads repo from context; inbox search is local State), `AdminThreadScreen(userId:, userName:, messages:, sender:, seen:, auth:)`.

Inbox row tap pushes the thread as a new route (back button returns to inbox — no shell changes beyond the tab). Exact tap code (`read` calls run in the tap callback, post-build, so they are safe):
```dart
onTap: () {
  final messages = context.read<MessageRepository>();
  final sender = context.read<SendMessageUseCase>();
  final seen = context.read<MarkSeenUseCase>();
  final auth = context.read<AuthRepository>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AdminThreadScreen(
        userId: conversation.userId,
        userName: conversation.userName,
        messages: messages,
        sender: sender,
        seen: seen,
        auth: auth,
      ),
    ),
  );
},
```

`admin_thread_screen.dart` (full code):

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/viewmodels/thread_viewmodel.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/widgets/thread_view.dart';

class AdminThreadScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final MessageRepository messages;
  final SendMessageUseCase sender;
  final MarkSeenUseCase seen;
  final AuthRepository auth;

  const AdminThreadScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.messages,
    required this.sender,
    required this.seen,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThreadViewModel>(
      create: (_) => ThreadViewModel(
        messages: messages,
        sender: sender,
        seen: seen,
        auth: auth,
      )..openThread(userId),
      child: Scaffold(
        appBar: AppBar(
          title: Text(userName.isEmpty ? 'Customer' : userName),
        ),
        body: ThreadView(otherLabel: _firstName(userName)),
      ),
    );
  }

  static String _firstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'Customer';
    return parts.first;
  }
}
```

- [ ] **Step 1: Write the failing test**

```dart
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/mock_message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/views/admin_inbox_screen.dart';
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _admin = AppUser(
  uid: 'admin-1',
  fullName: 'Shop Staff',
  email: 'admin@ferrer.ph',
  phone: '09171234567',
  role: UserRole.admin,
);

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_admin);

  @override
  Future<Result<AppUser>> signIn(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signUp(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendSignInLink(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signInWithEmailLink(
          {required String email,
          required String link,
          String? fullName,
          String? phone,
          String? password}) =>
      throw UnimplementedError();

  @override
  Stream<String> emailLinkStream() => Stream<String>.empty();

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<void>> updateProfile(
          {String? fullName,
          String? phone,
          String? address,
          List<String>? savedPlaces}) =>
      throw UnimplementedError();

  @override
  Stream<int> usersCountStream() => Stream<int>.empty();
}

Future<MessageRepository> _seededRepo() async {
  final repo = MessageRepositoryImpl(MockMessageDataSource());
  await repo.sendMessage(
    threadUserId: 'u2',
    senderId: 'u2',
    senderRole: 'customer',
    userName: 'Ana Reyes',
    text: 'Do you have this in blue?',
  );
  await repo.markSeen('u2', 'admin');
  await repo.sendMessage(
    threadUserId: 'u1',
    senderId: 'u1',
    senderRole: 'customer',
    userName: 'Maria Santos',
    text: 'Is Saturday fitting open?',
  );
  return repo;
}

Widget _harness(MessageRepository repo) {
  return MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: FakeAuthRepository()),
      Provider<MessageRepository>.value(value: repo),
      Provider<SendMessageUseCase>(
        create: (c) => SendMessageUseCase(c.read<MessageRepository>()),
      ),
      Provider<MarkSeenUseCase>(
        create: (c) => MarkSeenUseCase(c.read<MessageRepository>()),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: AdminInboxScreen())),
  );
}

void main() {
  testWidgets('inbox orders by recency with unread dot', (t) async {
    await t.pumpWidget(_harness(await _seededRepo()));
    await t.pumpAndSettle();
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('Ana Reyes'), findsOneWidget);
    // Maria sent later: her row sorts first.
    final mariaY = t.getCenter(find.text('Maria Santos')).dy;
    final anaY = t.getCenter(find.text('Ana Reyes')).dy;
    expect(mariaY, lessThan(anaY));
    expect(find.byKey(const ValueKey('unread-u1')), findsOneWidget);
    expect(find.byKey(const ValueKey('unread-u2')), findsNothing);
  });

  testWidgets('search filters threads by name', (t) async {
    await t.pumpWidget(_harness(await _seededRepo()));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('inbox-search')), 'Ana');
    await t.pumpAndSettle();
    expect(find.text('Ana Reyes'), findsOneWidget);
    expect(find.text('Maria Santos'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/messaging/admin_inbox_test.dart`
Expected: FAIL — classes undefined.

- [ ] **Step 3: Write minimal implementation**

`admin_inbox_screen.dart` (full code — inbox needs no viewmodel; the
search filter is local UI state and streams come straight from the
repository, the same pattern `ItemReviewList` uses):

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/views/admin_thread_screen.dart';

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              key: const ValueKey('inbox-search'),
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search customers',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Conversation>>(
              stream: context
                  .read<MessageRepository>()
                  .watchInbox(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.adminPrimary),
                  );
                }
                final threads = (snapshot.data ?? const [])
                    .where((c) => _query.isEmpty ||
                        c.userName.toLowerCase().contains(_query))
                    .toList();
                if (threads.isEmpty) {
                  return const Center(
                    child: Text(
                      'No conversations yet.',
                      style: TextStyle(
                          color: AppColors.adminMuted, fontSize: 14),
                    ),
                  );
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: threads.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final conversation = threads[index];
                    return _InboxRow(
                      conversation: conversation,
                      onTap: () {
                        final messages =
                            context.read<MessageRepository>();
                        final sender =
                            context.read<SendMessageUseCase>();
                        final seen =
                            context.read<MarkSeenUseCase>();
                        final auth =
                            context.read<AuthRepository>();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminThreadScreen(
                              userId: conversation.userId,
                              userName: conversation.userName,
                              messages: messages,
                              sender: sender,
                              seen: seen,
                              auth: auth,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _InboxRow({required this.conversation, required this.onTap});

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.adminPrimarySoft,
          foregroundColor: AppColors.adminPrimary,
          child: Text(
            _initials(conversation.userName),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          conversation.userName.isEmpty
              ? 'Customer'
              : conversation.userName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.adminInk),
        ),
        subtitle: Text(
          conversation.lastText.isEmpty
              ? 'No messages yet.'
              : conversation.lastText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.unreadForAdmin)
              Container(
                key: ValueKey('unread-${conversation.userId}'),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.adminRed,
                  shape: BoxShape.circle,
                ),
              ),
            if (conversation.updatedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                Formatters.timeAgo(conversation.updatedAt!),
                style: const TextStyle(
                    fontSize: 10.5, color: AppColors.adminMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

Deviation from spec §6 (record in commit message AND fix the spec file in
this same task): per-thread unread *counts* are unimplementable with
timestamp-only read state, so the inbox shows a DOT only. Edit
`docs/specs/2026-09-20-messaging-design.md` §6: "unread dot + count" →
"unread dot". The customer tab-bar count (spec §7) stays — it is computable
from the messages stream by filtering `senderRole` + timestamp.

`admin_thread_screen.dart`: full code is specified above (AppBar with customer
name, body is `ThreadView(otherLabel: <customer first name>)`, VM created in
the route with `..openThread(userId)`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/messaging/admin_inbox_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit** (include the spec §6 one-line fix)

```bash
git add lib/features/messaging/presentation/views docs/specs/2026-09-20-messaging-design.md test/features/messaging/admin_inbox_test.dart
git commit -m "Add admin messaging inbox and thread screen"
```

### Task 8: Shell tabs, badges, providers, index shifts

**Files:**
- Modify: `lib/main.dart:43-53` (add MessageRepository + SendMessageUseCase + MarkSeenUseCase providers)
- Modify: `lib/features/shell/presentation/views/user_shell.dart` (Messages destination at index 4, Profile 4→5, avatar tap 4→5, badge from thread stream)
- Modify: `lib/features/admin/admin_shell.dart` (Messages destination at index 5, Reports 5→6, badge from inbox stream)
- Test: `test/features/messaging/messaging_shell_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 4–7.
- Produces: 6-tab user bar, 7-tab admin bar, correct deep-link indices.

- [ ] **Step 1: Write the failing test**

- [ ] **Step 1: Write the failing test**

```dart
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/admin/admin_shell.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/mock_message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/cancel_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:ferrer_rental_shop/features/shell/presentation/views/user_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _customer = AppUser(
  uid: 'u1',
  fullName: 'Maria Santos',
  email: 'maria@example.com',
  phone: '09171234567',
  role: UserRole.customer,
);

const _admin = AppUser(
  uid: 'admin-1',
  fullName: 'Shop Staff',
  email: 'admin@ferrer.ph',
  phone: '09171234567',
  role: UserRole.admin,
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.user);

  final AppUser user;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(user);

  @override
  Future<Result<AppUser>> signIn(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signUp(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendSignInLink(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signInWithEmailLink(
          {required String email,
          required String link,
          String? fullName,
          String? phone,
          String? password}) =>
      throw UnimplementedError();

  @override
  Stream<String> emailLinkStream() => Stream<String>.empty();

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<void>> updateProfile(
          {String? fullName,
          String? phone,
          String? address,
          List<String>? savedPlaces}) =>
      throw UnimplementedError();

  @override
  Stream<int> usersCountStream() => Stream<int>.empty();
}

class FakeRentalRepository implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream<List<Rental>>.value([]);

  @override
  Stream<List<Rental>> allRentalsStream() =>
      Stream<List<Rental>>.value([]);

  @override
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) =>
      Stream<List<Rental>>.value([]);

  @override
  Future<String> createRental(Rental rental) async => 'new-id';

  @override
  Future<void> completeRental(String id, {DateTime? returnedAt}) async {}

  @override
  Future<void> cancelRental(String id) async {}

  @override
  Future<void> updateRentalStatus(String id, String status,
          {String? declineReason}) async {}
}

class FakeAppointmentRepository implements AppointmentRepository {
  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) =>
      Stream<List<Appointment>>.value([]);

  @override
  Stream<List<Appointment>> allAppointmentsStream() =>
      Stream<List<Appointment>>.value([]);

  @override
  Stream<List<Appointment>> pagedAppointmentsStream({int limit = 20}) =>
      Stream<List<Appointment>>.value([]);

  @override
  Future<List<String>> bookedSlotsFor(DateTime day) async => [];

  @override
  Future<void> createAppointment(Appointment appointment) async {}

  @override
  Future<void> cancelAppointment(String id) async {}

  @override
  Future<void> updateStatus(String id, String status,
          {String? declineReason}) async {}
}

class FakeInventoryRepository implements InventoryRepository {
  @override
  Stream<List<CatalogItem>> itemsStream() =>
      Stream<List<CatalogItem>>.value([]);

  @override
  Future<String> addItem(CatalogItem item) async => 'x';

  @override
  Future<void> updateItem(CatalogItem item) async {}

  @override
  Future<void> updateStatus(String itemId, String status) async {}

  @override
  Future<void> saveItemPhotos(String itemId, List<String> photos) async {}

  @override
  Future<List<String>> itemPhotos(String itemId) async => [];
}

class FakeReviewRepository implements ReviewRepository {
  @override
  Stream<Review?> reviewForRentalStream(String rentalId) =>
      Stream<Review?>.value(null);

  @override
  Stream<List<Review>> itemReviewsStream(String itemId) =>
      Stream<List<Review>>.value([]);

  @override
  Stream<RatingSummary> ratingSummaryStream(String itemId) =>
      Stream.value(RatingSummary.empty);

  @override
  Future<void> saveReview(Review review) async {}
}

bool _badgeWith(WidgetTester t, String label) => find
    .byWidgetPredicate(
        (w) => w is Badge && (w.label as Text?)?.data == label)
    .evaluate()
    .isNotEmpty;

List<SingleChildWidget> _baseProviders({
  required AuthRepository auth,
  required RentalRepository rentals,
  required AppointmentRepository appointments,
  required InventoryRepository inventory,
  required ReviewRepository reviews,
  required MessageRepository messages,
}) {
  return [
    Provider<AuthRepository>.value(value: auth),
    ChangeNotifierProvider<AuthViewModel>(
      create: (c) => AuthViewModel(c.read<AuthRepository>()),
    ),
    Provider<InventoryRepository>.value(value: inventory),
    Provider<RentalRepository>.value(value: rentals),
    Provider<AppointmentRepository>.value(value: appointments),
    Provider<ReviewRepository>.value(value: reviews),
    Provider<MessageRepository>.value(value: messages),
    Provider<SendMessageUseCase>(
      create: (c) => SendMessageUseCase(c.read<MessageRepository>()),
    ),
    Provider<MarkSeenUseCase>(
      create: (c) => MarkSeenUseCase(c.read<MessageRepository>()),
    ),
    Provider<ProcessReturnUseCase>(
      create: (c) => ProcessReturnUseCase(
          c.read<RentalRepository>(), c.read<InventoryRepository>()),
    ),
    Provider<ConfirmRentalUseCase>(
      create: (c) => ConfirmRentalUseCase(c.read<RentalRepository>()),
    ),
    Provider<DeclineRentalUseCase>(
      create: (c) => DeclineRentalUseCase(
          c.read<RentalRepository>(), c.read<InventoryRepository>()),
    ),
    Provider<CancelRentalUseCase>(
      create: (c) => CancelRentalUseCase(
          c.read<RentalRepository>(), c.read<InventoryRepository>()),
    ),
  ];
}

void main() {
  testWidgets('user shell gains Messages tab with unread bubble',
      (t) async {
    final messages =
        MessageRepositoryImpl(MockMessageDataSource());
    await messages.sendMessage(
      threadUserId: 'u1',
      senderId: 'admin-1',
      senderRole: 'admin',
      userName: 'Maria Santos',
      text: 'Hello Maria',
    );
    await t.pumpWidget(
      MultiProvider(
        providers: _baseProviders(
          auth: FakeAuthRepository(_customer),
          rentals: FakeRentalRepository(),
          appointments: FakeAppointmentRepository(),
          inventory: FakeInventoryRepository(),
          reviews: FakeReviewRepository(),
          messages: messages,
        ),
        child: const MaterialApp(home: UserShell()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Messages'), findsWidgets);
    expect(_badgeWith(t, '1'), isTrue);
    await t.tap(find.byIcon(Icons.forum_outlined));
    await t.pumpAndSettle();
    expect(find.text('Hello Maria'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('admin shell gains Messages tab with inbox badge',
      (t) async {
    final messages =
        MessageRepositoryImpl(MockMessageDataSource());
    await messages.sendMessage(
      threadUserId: 'u1',
      senderId: 'u1',
      senderRole: 'customer',
      userName: 'Maria Santos',
      text: 'Is Saturday open?',
    );
    await t.pumpWidget(
      MultiProvider(
        providers: _baseProviders(
          auth: FakeAuthRepository(_admin),
          rentals: FakeRentalRepository(),
          appointments: FakeAppointmentRepository(),
          inventory: FakeInventoryRepository(),
          reviews: FakeReviewRepository(),
          messages: messages,
        ),
        child: const MaterialApp(home: AdminShell()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Messages'), findsWidgets);
    expect(_badgeWith(t, '1'), isTrue);
    await t.tap(find.byIcon(Icons.forum_outlined));
    await t.pumpAndSettle();
    expect(find.text('Maria Santos'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/messaging/messaging_shell_test.dart`
Expected: FAIL — 'Messages' not found.

- [ ] **Step 3: Write minimal implementation**

`main.dart` — insert after the `SubmitReviewUseCase` provider (lines 50-53):
```dart
      Provider<MessageRepository>.value(
        value: MessageRepositoryImpl(MessageRepositoryImpl.defaultDataSource()),
      ),
      Provider<SendMessageUseCase>(
        create: (context) =>
            SendMessageUseCase(context.read<MessageRepository>()),
      ),
      Provider<MarkSeenUseCase>(
        create: (context) =>
            MarkSeenUseCase(context.read<MessageRepository>()),
      ),
```
Add imports for the three messaging types at the top with the other feature imports.

`user_shell.dart`:
- Import `MessageRepository`, messaging screen, `AppUser`? (not needed), `Badge` is material.
- In `_UserShellViewState.build`, after `notificationsCount`, compute:
```dart
    final authUserId = context.watch<AuthViewModel>().user?.uid;
```
Does UserShell have AuthViewModel in scope? `AuthViewModel` is provided globally in main.dart (`ChangeNotifierProvider<AuthViewModel>`), and UserShell sits below `MaterialApp(home: AuthGate(...))` → yes, readable. (Confirm: `AuthGate` receives `authRepository` and returns shells; `AuthViewModel` provider wraps `MaterialApp`? main.dart lines 41-80: providers wrap `FerrerApp` which builds MaterialApp — global. ✓)
- Messages unread count: needs thread messages newer than lastSeenCustomer from shop. Streams: `watchThread(uid)` + `watchMessages(uid)`. In build (stateless-ish computation): use StreamBuilders? _UserShellViewState.build is sync. Pattern: compute inside a small `_MessagesBadge` widget:
```dart
class _MessagesBadge extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;

  const _MessagesBadge({
    required this.icon,
    required this.selectedIcon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthViewModel>().user?.uid;
    if (uid == null) return Icon(selected ? selectedIcon : icon);
    return StreamBuilder<Conversation?>(
      stream: context.read<MessageRepository>().watchThread(uid),
      builder: (context, threadSnap) {
        return StreamBuilder<List<ChatMessage>>(
          stream: context.read<MessageRepository>().watchMessages(uid),
          builder: (context, msgSnap) {
            final thread = threadSnap.data;
            final messages = msgSnap.data ?? const [];
            final seen = thread?.lastSeenCustomer;
            final count = messages
                .where((m) =>
                    m.senderRole == 'admin' &&
                    m.createdAt != null &&
                    (seen == null || m.createdAt!.isAfter(seen)))
                .length;
            final iconWidget = Icon(selected ? selectedIcon : icon);
            if (count <= 0) return iconWidget;
            return Badge(
              backgroundColor: AppColors.roseDark,
              textColor: Colors.white,
              label: Text(count > 9 ? '9+' : '$count'),
              child: iconWidget,
            );
          },
        );
      },
    );
  }
}
```
Needs imports: `AuthViewModel`, `MessageRepository`, `Conversation`, `ChatMessage`, `AppColors` (already), material (already).
- Insert destination at index 4 (after Notifications at 3, before Profile):
```dart
              NavigationDestination(
                icon: const _MessagesBadge(
                  icon: Icons.forum_outlined,
                  selectedIcon: Icons.forum_rounded,
                ),
                selectedIcon: const _MessagesBadge(
                  icon: Icons.forum_outlined,
                  selectedIcon: Icons.forum_rounded,
                  selected: true,
                ),
                label: 'Messages',
              ),
```
- IndexedStack: insert `const CustomerThreadScreen()` at position 4 (before ProfileScreenTab). CustomerThreadScreen must be const-constructible (no required params — VM created inside via providers; screen reads them from context like other tab screens).
- Avatar tap: line 89 `setState(() => _index = 4)` → `5`.
- Profile rentals row `onNavigateTo(2)` unchanged (Rentals stays 2). Notifications row `onNavigateTo?.call(1)` unchanged (Bookings stays 1). Router `initialTab: 2` unchanged.

`admin_shell.dart`:
- In `_AdminShellViewState.build`, compute unread thread count from inbox stream via a `_MessagesBadge`-style widget reading `MessageRepository().watchInbox()`:
```dart
class _MessagesBadge extends StatelessWidget {
  ...same shape, admin colors...
  StreamBuilder<List<Conversation>>(
    stream: context.read<MessageRepository>().watchInbox(),
    builder: (context, snapshot) {
      final count = (snapshot.data ?? const [])
          .where((c) => c.unreadForAdmin)
          .length;
      ...Badge(backgroundColor: AppColors.adminPrimary...) or plain icon
    },
  );
}
```
Check `AppColors.adminPrimary` exists (used in admin_shell badges per explore brief: `color: AppColors.adminPrimary`, `adminRed`). ✓
- Insert destination at index 5 (after Reviews, before Reports) with `Icons.forum_outlined/forum_rounded`; IndexedStack insert `const AdminInboxScreen()` at position 5. Dashboard deep-link indices (1, 3) unchanged; Reports shifts 5→6 with no literal references (verified: only 1 and 3 used).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/messaging/messaging_shell_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/features/shell lib/features/admin/admin_shell.dart test/features/messaging/messaging_shell_test.dart
git commit -m "Wire messaging tabs and badges into both shells"
```

### Task 9: Full verification

**Files:** none (verification only).

- [ ] **Step 1: Run analyzer**

Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 2: Run the full suite**

Run: `flutter test`
Expected: All tests passed! (previous count + ~25 new).

- [ ] **Step 3: Self-review against the spec**

Checklist (do this yourself, fix inline, no subagent):
1. Spec coverage: §3 data (thread/message fields, implicit create, markSeen no-op) → Tasks 2–4; §4 rules+indexes → Task 3 (+deploy output); §5 customer UI → Task 6+8; §6 admin UI → Task 7+8; §7 badges/errors/testing → Tasks 6–8; §8 exclusions intact (no FCM/images/typing/edit/delete/staff identity); §9 file list matches reality.
2. Placeholder scan: no TBD/TODO/bare "handle edge cases".
3. Type consistency: `watchMessages(userId, {limit})`, `sendMessage({...})`, `markSeen(userId, role)` signatures identical across interface/impl/mock/tests; `RatingSummary`-style naming not leaked in; `AppUser(...)` ctor args match `app_user.dart:16-24` exactly.

- [ ] **Step 4: Commit anything fixed by the review** (or nothing)

```bash
git status --short
# commit only if review changed files
```

## Execution Handoff

(Handled by the assistant after plan approval — not part of the plan file.)
