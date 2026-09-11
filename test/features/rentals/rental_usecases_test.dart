import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/cancel_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/create_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRentalRepository implements RentalRepository {
  int createCalls = 0;
  int completeCalls = 0;
  int cancelCalls = 0;
  final List<String> statusUpdates = [];
  bool throwOnCancel = false;
  bool throwOnStatusUpdate = false;
  DateTime? lastReturnedAt;

  @override
  Future<void> createRental(Rental rental) async => createCalls++;

  @override
  Future<void> completeRental(String id, {DateTime? returnedAt}) async {
    completeCalls++;
    lastReturnedAt = returnedAt;
  }

  @override
  Future<void> cancelRental(String id) async {
    cancelCalls++;
    if (throwOnCancel) throw Exception('db down');
  }

  @override
  Future<void> updateRentalStatus(String id, String status,
      {String? declineReason}) async {
    if (throwOnStatusUpdate) throw Exception('db down');
    statusUpdates.add(status);
  }

  @override
  Stream<List<Rental>> userRentalsStream(String userId) => const Stream.empty();

  @override
  Stream<List<Rental>> allRentalsStream() => const Stream.empty();
}

class FakeInventoryRepository implements InventoryRepository {
  final List<(String, String)> statusUpdates = [];

  /// Catalog snapshot served to availability checks; tests mutate item
  /// status through this list (e.g. mark 'rented' to simulate a race).
  final List<CatalogItem> catalog = [
    CatalogItem(
      id: 'i1',
      name: 'Gown',
      category: 'dress',
      basePrice: 500,
      securityDeposit: 1000,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Future<String> addItem(CatalogItem item) async => 'new-id';

  @override
  Future<List<String>> itemPhotos(String itemId) async => [];

  @override
  Stream<List<CatalogItem>> itemsStream() async* {
    yield List.unmodifiable(catalog);
  }

  @override
  Future<void> saveItemPhotos(String itemId, List<String> photos) async {}

  @override
  Future<void> updateItem(CatalogItem item) async {}

  @override
  Future<void> updateStatus(String itemId, String status) async {
    statusUpdates.add((itemId, status));
  }
}

Rental _rental({DateTime? start, DateTime? end, String status = 'active'}) {
  final now = DateTime.now();
  return Rental(
    id: 'r1',
    userId: 'u1',
    userName: 'Jane',
    itemId: 'i1',
    itemName: 'Gown',
    startDate: start ?? now,
    endDate: end ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 4)),
    rentalFee: 1500,
    securityDeposit: 1000,
    total: 2500,
    status: status,
    createdAt: now,
  );
}

void main() {
  group('CreateRentalUseCase', () {
    test('creates rental and marks item rented', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = CreateRentalUseCase(rentals, inventory);

      await usecase.execute(_rental());

      expect(rentals.createCalls, 1);
      expect(inventory.statusUpdates, [('i1', 'rented')]);
    });

    test('throws FormatException when end is not after start', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = CreateRentalUseCase(rentals, inventory);
      final now = DateTime.now();

      expect(
        () => usecase.execute(_rental(start: now, end: now)),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => usecase.execute(
          _rental(start: now, end: now.subtract(const Duration(days: 1))),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(rentals.createCalls, 0);
    });

    test('throws FormatException when period is not fixed 5 days', () async {      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = CreateRentalUseCase(rentals, inventory);
      final now = DateTime.now();

      expect(
        () => usecase.execute(
          _rental(start: now, end: now.add(const Duration(days: 3))),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(rentals.createCalls, 0);
    });

    test('refuses when the item is no longer available', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = CreateRentalUseCase(rentals, inventory);
      inventory.catalog[0] =
          inventory.catalog[0].copyWith(status: 'rented');

      expect(
        () => usecase.execute(_rental()),
        throwsA(isA<FormatException>()),
      );
      expect(rentals.createCalls, 0);
    });
  });

  group('CancelRentalUseCase', () {
    test('cancels rental and frees item', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = CancelRentalUseCase(rentals, inventory);

      await usecase.execute(_rental());

      expect(rentals.cancelCalls, 1);
      expect(inventory.statusUpdates, [('i1', 'available')]);
    });

    test('wraps repository errors in NetworkFailure', () async {
      final rentals = FakeRentalRepository()..throwOnCancel = true;
      final inventory = FakeInventoryRepository();
      final usecase = CancelRentalUseCase(rentals, inventory);

      expect(() => usecase.execute(_rental()),
          throwsA(isA<NetworkFailure>()));
    });

    test('refuses completed, cancelled and overdue rentals', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = CancelRentalUseCase(rentals, inventory);
      final now = DateTime.now();

      expect(
        () => usecase.execute(_rental(status: 'completed')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => usecase.execute(_rental(status: 'cancelled')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => usecase.execute(_rental(
          status: 'active',
          start: now.subtract(const Duration(days: 10)),
          end: now.subtract(const Duration(days: 2)),
        )),
        throwsA(isA<FormatException>()),
      );
      expect(rentals.cancelCalls, 0);
      expect(inventory.statusUpdates, isEmpty);
    });
  });

  group('ConfirmRentalUseCase', () {
    test('confirms a pending rental to active', () async {
      final rentals = FakeRentalRepository();
      final usecase = ConfirmRentalUseCase(rentals);

      await usecase.execute(_rental(status: 'pending'));

      expect(rentals.statusUpdates, ['active']);
    });

    test('refuses to confirm a rental that is not pending', () async {
      final rentals = FakeRentalRepository();
      final usecase = ConfirmRentalUseCase(rentals);

      expect(
        () => usecase.execute(_rental(status: 'active')),
        throwsA(isA<FormatException>()),
      );
      expect(rentals.statusUpdates, isEmpty);
    });

    test('wraps repository errors in NetworkFailure', () async {
      final rentals = FakeRentalRepository()..throwOnStatusUpdate = true;
      final usecase = ConfirmRentalUseCase(rentals);

      expect(() => usecase.execute(_rental(status: 'pending')),
          throwsA(isA<NetworkFailure>()));
    });
  });

  group('DeclineRentalUseCase', () {
    test('declines a pending rental and frees the item', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = DeclineRentalUseCase(rentals, inventory);

      await usecase.execute(_rental(status: 'pending'), reason: 'Out of stock');

      expect(rentals.statusUpdates, ['declined']);
      expect(inventory.statusUpdates, [('i1', 'available')]);
    });

    test('requires a reason', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = DeclineRentalUseCase(rentals, inventory);

      expect(
        () => usecase.execute(_rental(status: 'pending'), reason: '  '),
        throwsA(isA<FormatException>()),
      );
      expect(rentals.statusUpdates, isEmpty);
    });

    test('refuses to decline a rental that is not pending', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = DeclineRentalUseCase(rentals, inventory);

      expect(
        () => usecase.execute(_rental(status: 'completed'), reason: 'Nope'),
        throwsA(isA<FormatException>()),
      );
      expect(rentals.statusUpdates, isEmpty);
      expect(inventory.statusUpdates, isEmpty);
    });

    test('wraps repository errors in NetworkFailure', () async {
      final rentals = FakeRentalRepository()..throwOnStatusUpdate = true;
      final inventory = FakeInventoryRepository();
      final usecase = DeclineRentalUseCase(rentals, inventory);

      expect(() => usecase.execute(_rental(status: 'pending'), reason: 'Busy'),
          throwsA(isA<NetworkFailure>()));
    });
  });

  group('ProcessReturnUseCase', () {
    test('refunds full deposit when not overdue', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = ProcessReturnUseCase(rentals, inventory);
      final now = DateTime.now();
      final rental = _rental(
        start: now,
        end: now.add(const Duration(days: 3)),
      );

      final result = await usecase.execute(rental);

      expect(result.wasOverdue, isFalse);
      expect(result.depositRefunded, 1000);
      expect(result.itemName, 'Gown');
      expect(rentals.completeCalls, 1);
      expect(rentals.lastReturnedAt, isNotNull);
      expect(inventory.statusUpdates, [('i1', 'available')]);
    });

    test('refunds half deposit when overdue', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = ProcessReturnUseCase(rentals, inventory);
      final now = DateTime.now();
      final rental = _rental(
        start: now.subtract(const Duration(days: 5)),
        end: now.subtract(const Duration(days: 1)),
      );

      final result = await usecase.execute(rental);

      expect(result.wasOverdue, isTrue);
      expect(result.depositRefunded, 500);
    });

    test('refuses pending, cancelled and completed rentals', () async {
      final rentals = FakeRentalRepository();
      final inventory = FakeInventoryRepository();
      final usecase = ProcessReturnUseCase(rentals, inventory);

      for (final status in ['pending', 'cancelled', 'completed', 'declined']) {
        expect(
          () => usecase.execute(_rental(status: status)),
          throwsA(isA<FormatException>()),
        );
      }
      expect(rentals.completeCalls, 0);
      expect(inventory.statusUpdates, isEmpty);
    });
  });
}
