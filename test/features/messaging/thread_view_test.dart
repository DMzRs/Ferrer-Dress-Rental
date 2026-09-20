import 'package:ferrer_rental_shop/core/utils/result.dart';
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

  @override
  Stream<List<AppUser>> watchUsers() => Stream<List<AppUser>>.value([]);
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
        child: const MaterialApp(home: Scaffold(body: CustomerThreadScreen())),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Hello Maria'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'Thanks!');
    await t.tap(find.byIcon(Icons.send_rounded));
    await t.pumpAndSettle();
    expect(find.text('Thanks!'), findsOneWidget);
  });

  testWidgets('customer empty thread hides start button (types in composer)',
      (t) async {
    final repo = MessageRepositoryImpl(MockMessageDataSource());
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
        child: const MaterialApp(
            home: Scaffold(body: CustomerThreadScreen())),
      ),
    );
    await t.pumpAndSettle();
    // User side: no shortcut button — empty text + composer only.
    expect(find.text('Start conversation'), findsNothing);
    expect(find.text('No messages yet. Say hello!'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
