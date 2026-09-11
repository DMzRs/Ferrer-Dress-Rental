import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/checkout/presentation/viewmodels/checkout_viewmodel.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/create_rental_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRentals implements RentalRepository {
  Rental? lastCreated;
  bool shouldThrow = false;

  @override
  Future<void> createRental(Rental rental) async {
    if (shouldThrow) throw Exception('payment failed');
    lastCreated = rental;
  }

  @override
  Future<void> completeRental(String id, {DateTime? returnedAt}) async {}

  @override
  Future<void> cancelRental(String id) async {}

  @override
  Future<void> updateRentalStatus(String id, String status,
      {String? declineReason}) async {}

  @override
  Stream<List<Rental>> userRentalsStream(String userId) => const Stream.empty();

  @override
  Stream<List<Rental>> allRentalsStream() => const Stream.empty();
}

class _FakeInventory implements InventoryRepository {
  String? lastStatus;

  @override
  Future<String> addItem(CatalogItem item) async => 'x';

  @override
  Future<List<String>> itemPhotos(String itemId) async => [];

  @override
  Stream<List<CatalogItem>> itemsStream() => const Stream.empty();

  @override
  Future<void> saveItemPhotos(String id, List<String> p) async {}

  @override
  Future<void> updateItem(CatalogItem item) async {}

  @override
  Future<void> updateStatus(String id, String status) async {
    lastStatus = status;
  }
}

CatalogItem _item() => CatalogItem(
      id: 'i1',
      name: 'Gown',
      category: 'dress',
      basePrice: 500,
      securityDeposit: 1000,
      createdAt: DateTime(2026, 1, 1),
    );

const _user = AppUser(
  uid: 'u1',
  fullName: 'Jane Doe',
  email: 'j@x.com',
  phone: '0917',
  role: UserRole.customer,
);

CheckoutViewModel _vm(_FakeRentals r, _FakeInventory i) =>
    CheckoutViewModel(CreateRentalUseCase(r, i), _item());

void main() {
  group('CheckoutViewModel pricing', () {
    test('rentalDays fixed to 5', () {
      final vm = _vm(_FakeRentals(), _FakeInventory());
      expect(vm.rentalDays, 5);
      expect(vm.rentalFee, 2500);
      expect(vm.securityDeposit, 1000);
      expect(vm.total, 3500);
    });

    test('rentalFee fixed for 5 days', () {
      final vm = _vm(_FakeRentals(), _FakeInventory());
      vm.updateStartDate(DateTime.now().add(const Duration(days: 10)));
      expect(vm.rentalDays, 5);
      expect(vm.rentalFee, 2500);
      expect(vm.total, 3500);
    });
  });

  group('CheckoutViewModel dates', () {
    test('updateStartDate sets endDate to start + 4 days', () {
      final vm = _vm(_FakeRentals(), _FakeInventory());
      final start = DateTime.now().add(const Duration(days: 20));
      vm.updateStartDate(start);
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay =
          DateTime(vm.endDate.year, vm.endDate.month, vm.endDate.day);
      expect(endDay.difference(startDay).inDays, 4);
    });

    test('updateEndDate is fixed and reports error', () {
      final vm = _vm(_FakeRentals(), _FakeInventory());
      final before = vm.endDate;
      vm.updateEndDate(before.add(const Duration(days: 10)));
      expect(vm.endDate, before);
      expect(vm.error, contains('fixed to 5 days'));
    });
  });

  group('CheckoutViewModel.confirm', () {
    test('returns true and trims address on success', () async {
      final rentals = _FakeRentals();
      final inventory = _FakeInventory();
      final vm = _vm(rentals, inventory);

      final ok = await vm.confirm(_user, address: '  QC  ');

      expect(ok, isTrue);
      expect(vm.error, isNull);
      expect(vm.isConfirming, isFalse);
      expect(rentals.lastCreated!.deliveryAddress, 'QC');
      expect(rentals.lastCreated!.userId, 'u1');
      expect(rentals.lastCreated!.status, 'pending');
      expect(inventory.lastStatus, 'rented');
    });

    test('returns false with generic error on failure', () async {
      final rentals = _FakeRentals()..shouldThrow = true;
      final vm = _vm(rentals, _FakeInventory());

      final ok = await vm.confirm(_user, address: 'QC');

      expect(ok, isFalse);
      expect(vm.error, contains('Payment could not be completed'));
      expect(vm.isConfirming, isFalse);
    });
  });
}
