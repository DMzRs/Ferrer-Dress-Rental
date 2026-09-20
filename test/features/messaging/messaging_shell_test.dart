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
  Stream<List<Review>> allReviewsStream() =>
      Stream<List<Review>>.value([]);

  @override
  Future<void> saveReview(Review review) async {}
}

bool _badgeWith(WidgetTester t, String label) => find
    .byWidgetPredicate(
        (w) => w is Badge && (w.label as Text?)?.data == label)
    .evaluate()
    .isNotEmpty;

Future<void> _pumpShell(
  WidgetTester t,
  Widget home, {
  required AuthRepository auth,
  required RentalRepository rentals,
  required AppointmentRepository appointments,
  required InventoryRepository inventory,
  required ReviewRepository reviews,
  required MessageRepository messages,
}) {
  return t.pumpWidget(
    MultiProvider(
      providers: [
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
      ],
      child: MaterialApp(home: home),
    ),
  );
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
    await _pumpShell(
      t,
      const UserShell(),
      auth: FakeAuthRepository(_customer),
      rentals: FakeRentalRepository(),
      appointments: FakeAppointmentRepository(),
      inventory: FakeInventoryRepository(),
      reviews: FakeReviewRepository(),
      messages: messages,
    );
    await t.pumpAndSettle();
    expect(find.text('Messages'), findsWidgets);
    expect(_badgeWith(t, '1'), isTrue);
    await t.tap(find.byIcon(Icons.forum_outlined));
    await t.pumpAndSettle();
    expect(find.text('Hello Maria'), findsOneWidget);
    // Opening the tab marks read: the bubble clears.
    expect(_badgeWith(t, '1'), isFalse);
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
    await _pumpShell(
      t,
      const AdminShell(),
      auth: FakeAuthRepository(_admin),
      rentals: FakeRentalRepository(),
      appointments: FakeAppointmentRepository(),
      inventory: FakeInventoryRepository(),
      reviews: FakeReviewRepository(),
      messages: messages,
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
