import 'package:ferrer_rental_shop/features/admin/rental_management/presentation/viewmodels/rental_management_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/rental_management/presentation/views/rental_management_screen.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Rental _rental(String id, String name, DateTime end) => Rental(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: name,
      startDate: end.subtract(const Duration(days: 4)),
      endDate: end,
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: 'active',
      createdAt: DateTime(2026, 9, 1),
    );

class _TabRentalRepository implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream<List<Rental>>.value(const []);

  @override
  Stream<List<Rental>> allRentalsStream() =>
      Stream<List<Rental>>.value(const []);

  @override
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) {
    final now = DateTime.now();
    return Stream.value([
      _rental('a1', 'Plain One', now.add(const Duration(days: 2))),
      _rental('a2', 'Plain Two', now.add(const Duration(days: 3))),
      _rental('o1', 'Overdue One', now.subtract(const Duration(days: 1))),
      _rental('o2', 'Overdue Two', now.subtract(const Duration(days: 2))),
    ]);
  }

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

class _TabInventoryRepository implements InventoryRepository {
  @override
  Stream<List<CatalogItem>> itemsStream() =>
      Stream<List<CatalogItem>>.value(const []);

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

class _TabReviewRepository implements ReviewRepository {
  @override
  Stream<Review?> reviewForRentalStream(String rentalId) =>
      Stream<Review?>.value(null);

  @override
  Stream<List<Review>> itemReviewsStream(String itemId) =>
      Stream<List<Review>>.value(const []);

  @override
  Stream<RatingSummary> ratingSummaryStream(String itemId) =>
      Stream.value(RatingSummary.empty);

  @override
  Stream<List<Review>> allReviewsStream() =>
      Stream<List<Review>>.value(const []);

  @override
  Future<void> saveReview(Review review) async {}
}

void main() {
  testWidgets('active tab lists plain actives only, no overdue cards',
      (t) async {
    final rentals = _TabRentalRepository();
    final inventory = _TabInventoryRepository();
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RentalManagementViewModel>(
            create: (_) => RentalManagementViewModel(
              rentals,
              ProcessReturnUseCase(rentals, inventory),
              ConfirmRentalUseCase(rentals),
              DeclineRentalUseCase(rentals, inventory),
            ),
          ),
          Provider<ReviewRepository>.value(value: _TabReviewRepository()),
        ],
        child: const MaterialApp(home: RentalManagementScreen()),
      ),
    );
    await t.pumpAndSettle();

    // Default tab is Active: exactly the 2 plain cards, zero OVERDUE pills.
    expect(find.text('Plain One'), findsOneWidget);
    expect(find.text('Plain Two'), findsOneWidget);
    expect(find.text('OVERDUE'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
