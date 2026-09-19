import 'dart:async';

import 'package:ferrer_rental_shop/features/admin/rental_management/presentation/viewmodels/rental_management_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/rental_management/presentation/views/rental_management_screen.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Rental _rental() => Rental(
      id: 'r1',
      userId: 'u1',
      userName: 'Maria Santos',
      itemId: 'i1',
      itemName: 'Gown',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 5)),
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: 'pending',
      createdAt: DateTime.now(),
    );

class _FakeRentalRepository implements RentalRepository {
  _FakeRentalRepository({this.throwOnStatusUpdate = false}) {
    _controller.add([_rental()]);
  }

  final bool throwOnStatusUpdate;
  final _controller =
      StreamController<List<Rental>>.broadcast();

  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      Stream<List<Rental>>.empty();

  @override
  Stream<List<Rental>> allRentalsStream() async* {
    yield [_rental()];
    yield* _controller.stream;
  }

  @override
  @override
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) =>
      allRentalsStream();

  @override
  Future<String> createRental(Rental rental) async => 'new-id';

  @override
  Future<void> completeRental(String id, {DateTime? returnedAt}) async {}

  @override
  Future<void> cancelRental(String id) async {}

  @override
  Future<void> updateRentalStatus(String id, String status,
      {String? declineReason}) async {
    if (throwOnStatusUpdate) throw Exception('db down');
    _controller.add([
      Rental(
        id: 'r1',
        userId: 'u1',
        userName: 'Maria Santos',
        itemId: 'i1',
        itemName: 'Gown',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        rentalFee: 500,
        securityDeposit: 200,
        total: 700,
        status: status,
        createdAt: DateTime.now(),
      ),
    ]);
  }
}

class _FakeInventoryRepository implements InventoryRepository {
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

Widget _harness({bool failDecline = false}) {
  final rentals = _FakeRentalRepository(throwOnStatusUpdate: failDecline);
  final inventory = _FakeInventoryRepository();
  return MultiProvider(
    providers: [
      Provider<RentalRepository>.value(value: rentals),
      Provider<InventoryRepository>.value(value: inventory),
      ChangeNotifierProvider<RentalManagementViewModel>(
        create: (c) => RentalManagementViewModel(
          c.read<RentalRepository>(),
          ProcessReturnUseCase(
              c.read<RentalRepository>(), c.read<InventoryRepository>()),
          ConfirmRentalUseCase(c.read<RentalRepository>()),
          DeclineRentalUseCase(
              c.read<RentalRepository>(), c.read<InventoryRepository>()),
        ),
      ),
    ],
    child: const MaterialApp(home: RentalManagementScreen()),
  );
}

Future<void> _openDeclineSheet(WidgetTester t) async {
  await t.pumpWidget(_harness(failDecline: true));
  await t.pumpAndSettle();
  await t.tap(find.textContaining('Requests'));
  await t.pumpAndSettle();
  await t.tap(find.text('Decline'));
  await t.pumpAndSettle();
  await t.enterText(find.byType(TextField), 'Shop closed that week');
  await t.pumpAndSettle();
}

void main() {
  testWidgets('decline failure shows snackbar without ancestor errors',
      (t) async {
    final errs = <FlutterErrorDetails>[];
    final prev = FlutterError.onError;
    FlutterError.onError = errs.add;
    try {
      await _openDeclineSheet(t);
      await t.tap(find.text('Decline and Notify'));
      await t.pumpAndSettle();
    } finally {
      FlutterError.onError = prev;
    }
    expect(
      errs.where((e) => '$e'.contains('deactivated')).toList(),
      isEmpty,
    );
    expect(t.takeException(), isNull);
    expect(find.text('Could not decline this rental. Please try again.'),
        findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
  });

  testWidgets('decline success with live stream has no ancestor errors',
      (t) async {
    final errs = <FlutterErrorDetails>[];
    final prev = FlutterError.onError;
    FlutterError.onError = errs.add;
    try {
      await t.pumpWidget(_harness());
      await t.pumpAndSettle();
      await t.tap(find.textContaining('Requests'));
      await t.pumpAndSettle();
      await t.tap(find.text('Decline'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Shop closed that week');
      await t.pumpAndSettle();
      await t.tap(find.text('Decline and Notify'));
      await t.pumpAndSettle();
    } finally {
      FlutterError.onError = prev;
    }
    expect(
      errs.where((e) => '$e'.contains('deactivated')).toList(),
      isEmpty,
    );
    expect(t.takeException(), isNull);
  });
}
