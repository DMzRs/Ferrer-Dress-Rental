import 'package:ferrer_rental_shop/features/admin/rental_management/presentation/viewmodels/rental_management_viewmodel.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:flutter_test/flutter_test.dart';

Rental _rental(String id, DateTime end) => Rental(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Gown',
      startDate: end.subtract(const Duration(days: 5)),
      endDate: end,
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: 'active',
      createdAt: DateTime(2026, 9, 1),
    );

class _TabsRentalRepository implements RentalRepository {
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
      _rental('a1', now.add(const Duration(days: 2))),
      _rental('a2', now.add(const Duration(days: 3))),
      _rental('o1', now.subtract(const Duration(days: 1))),
      _rental('o2', now.subtract(const Duration(days: 2))),
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

class _TabsInventoryRepository implements InventoryRepository {
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

void main() {
  test('active tab excludes overdue, matching its badge count', () async {
    final rentals = _TabsRentalRepository();
    final inventory = _TabsInventoryRepository();
    final vm = RentalManagementViewModel(
      rentals,
      ProcessReturnUseCase(rentals, inventory),
      ConfirmRentalUseCase(rentals),
      DeclineRentalUseCase(rentals, inventory),
    );
    addTearDown(vm.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(vm.activeCount, 2);
    expect(vm.overdueCount, 2);
    vm.setTab(RentalTab.active);
    expect(vm.rentals.map((r) => r.id), ['a1', 'a2']);
    vm.setTab(RentalTab.overdue);
    expect(vm.rentals.map((r) => r.id), ['o1', 'o2']);
  });

  test('short filtered tabs hide Load more even at the page limit', () async {
    final rentals = _TabsRentalRepository();
    final inventory = _TabsInventoryRepository();
    final vm = RentalManagementViewModel(
      rentals,
      ProcessReturnUseCase(rentals, inventory),
      ConfirmRentalUseCase(rentals),
      DeclineRentalUseCase(rentals, inventory),
    );
    addTearDown(vm.dispose);
    await Future<void>.delayed(Duration.zero);

    // 4 fetched at the default page size of 20: the server signal says
    // "maybe more", but a 2-card tab must not offer it.
    expect(vm.hasMore, isFalse);
    expect(vm.canLoadMoreFor(2), isFalse);
  });

  test('full tabs keep Load more while the server may hold more', () async {
    final rentals = _FullPageRentalRepository();
    final inventory = _TabsInventoryRepository();
    final vm = RentalManagementViewModel(
      rentals,
      ProcessReturnUseCase(rentals, inventory),
      ConfirmRentalUseCase(rentals),
      DeclineRentalUseCase(rentals, inventory),
    );
    addTearDown(vm.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(vm.hasMore, isTrue);
    expect(vm.canLoadMoreFor(20), isTrue);
    vm.loadMore();
    await Future<void>.delayed(Duration.zero);
    expect(vm.canLoadMoreFor(20), isFalse);
  });

  test('attention count covers pending, active and overdue', () async {
    final rentals = _TabsRentalRepository();
    final inventory = _TabsInventoryRepository();
    final vm = RentalManagementViewModel(
      rentals,
      ProcessReturnUseCase(rentals, inventory),
      ConfirmRentalUseCase(rentals),
      DeclineRentalUseCase(rentals, inventory),
    );
    addTearDown(vm.dispose);
    await Future<void>.delayed(Duration.zero);

    // 2 plain active + 2 overdue, no pending.
    expect(vm.attentionCount, 4);
  });
}

class _FullPageRentalRepository extends _TabsRentalRepository {
  @override
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) {
    final now = DateTime.now();
    return Stream.value(List.generate(
      limit,
      (i) => _rental('f$i', now.add(Duration(days: i + 1))),
    ));
  }
}
