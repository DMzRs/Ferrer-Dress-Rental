import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/data/datasources/mock_message_data_source.dart';
import 'package:ferrer_rental_shop/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/views/admin_inbox_screen.dart';
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
  FakeAuthRepository({this.directory = const []});

  final List<AppUser> directory;

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

  @override
  Stream<List<AppUser>> watchUsers() => Stream.value(directory);
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
  await Future<void>.delayed(const Duration(milliseconds: 5));
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

  testWidgets('new-message button opens picker and starts a thread', (t) async {
    const maria = AppUser(
      uid: 'u9',
      fullName: 'Maria Santos',
      email: 'maria@example.com',
      phone: '0917',
      role: UserRole.customer,
    );
    final repo = MessageRepositoryImpl(MockMessageDataSource());
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(
              value: FakeAuthRepository(directory: const [maria])),
          Provider<MessageRepository>.value(value: repo),
          Provider<SendMessageUseCase>(
            create: (c) => SendMessageUseCase(c.read<MessageRepository>()),
          ),
          Provider<MarkSeenUseCase>(
            create: (c) => MarkSeenUseCase(c.read<MessageRepository>()),
          ),
        ],
        child:
            const MaterialApp(home: Scaffold(body: AdminInboxScreen())),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('new-message')));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const ValueKey('customer-search')), 'Maria');
    await t.pumpAndSettle();
    expect(find.text('Maria Santos'), findsWidgets);
    await t.tap(find.text('Maria Santos').last);
    await t.pumpAndSettle();
    expect(find.text('No messages yet. Say hello!'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
  });
}
