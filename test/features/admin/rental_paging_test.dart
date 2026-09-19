import 'package:ferrer_rental_shop/features/admin/rental_management/presentation/viewmodels/rental_management_viewmodel.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

Rental _rental(String id) => Rental(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Gown $id',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 5),
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: 'active',
      createdAt: DateTime(2026, 8, 1),
    );

class _FakeRentalRepository implements RentalRepository {
  final List<Rental> all =
      List.generate(25, (i) => _rental('r$i'));

  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream<List<Rental>>.empty();

  @override
  Stream<List<Rental>> allRentalsStream() => Stream.value(all);

  @override
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) =>
      Stream.value(all.take(limit).toList());

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
      Stream<List<CatalogItem>>.empty();

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

RentalManagementViewModel _vm(RentalRepository rentals) =>
    RentalManagementViewModel(
      rentals,
      ProcessReturnUseCase(rentals, _FakeInventoryRepository()),
      ConfirmRentalUseCase(rentals),
      DeclineRentalUseCase(rentals, _FakeInventoryRepository()),
    );

void main() {
  test('starts paged at 20 with more available', () async {
    final vm = _vm(_FakeRentalRepository());
    await Future<void>.delayed(Duration.zero);
    expect(vm.pageSize, 20);
    expect(vm.rentals.length, 20);
    expect(vm.hasMore, isTrue);
    vm.dispose();
  });

  test('loadMore grows the page', () async {
    final vm = _vm(_FakeRentalRepository());
    await Future<void>.delayed(Duration.zero);
    vm.loadMore();
    await Future<void>.delayed(Duration.zero);
    expect(vm.pageSize, 40);
    expect(vm.rentals.length, 25);
    expect(vm.hasMore, isFalse);
    vm.dispose();
  });
}
