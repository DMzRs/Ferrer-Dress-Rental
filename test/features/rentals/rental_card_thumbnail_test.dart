import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/viewmodels/my_rentals_viewmodel.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/views/my_rentals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _user = AppUser(
  uid: 'u1',
  fullName: 'Maria',
  email: 'm@m.com',
  phone: '0917',
  role: UserRole.customer,
);

// 1x1 transparent PNG.
const _thumb =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Rental _rental() => Rental(
      id: 'r1',
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Blush Satin Evening Gown',
      startDate: DateTime(2026, 9, 18),
      endDate: DateTime(2026, 9, 20),
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: 'pending',
      createdAt: DateTime(2026, 9, 17),
    );

CatalogItem _item() => CatalogItem(
      id: 'i1',
      name: 'Blush Satin Evening Gown',
      category: 'dress',
      basePrice: 1800,
      securityDeposit: 1000,
      thumbnail: _thumb,
      createdAt: DateTime(2026, 9, 1),
    );

class _FakeRentalRepository implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream<List<Rental>>.value([_rental()]);

  @override
  Stream<List<Rental>> allRentalsStream() =>
      Stream<List<Rental>>.value(const []);

  @override
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) =>
      Stream<List<Rental>>.value(const []);

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

class _FakeInventoryRepository implements InventoryRepository {
  @override
  Stream<List<CatalogItem>> itemsStream() =>
      Stream<List<CatalogItem>>.value([_item()]);

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

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_user);

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
  testWidgets('rentals list shows the item photo, not a placeholder',
      (t) async {
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: _FakeAuthRepository()),
          Provider<InventoryRepository>.value(
              value: _FakeInventoryRepository()),
          Provider<RentalRepository>.value(value: _FakeRentalRepository()),
          ChangeNotifierProvider<MyRentalsViewModel>(
            create: (c) => MyRentalsViewModel(
              c.read<RentalRepository>(),
              c.read<AuthRepository>(),
            ),
          ),
        ],
        child: const MaterialApp(
            home: Scaffold(body: MyRentalsScreen())),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Blush Satin Evening Gown'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });
}
