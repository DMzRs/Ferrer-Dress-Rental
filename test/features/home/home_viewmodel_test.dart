import 'dart:async';

import 'package:ferrer_rental_shop/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInventory implements InventoryRepository {
  final _controller = StreamController<List<CatalogItem>>.broadcast();

  void emit(List<CatalogItem> items) => _controller.add(items);

  @override
  Stream<List<CatalogItem>> itemsStream() => _controller.stream;

  @override
  Future<String> addItem(CatalogItem item) async => 'x';

  @override
  Future<List<String>> itemPhotos(String itemId) async => [];

  @override
  Future<void> saveItemPhotos(String id, List<String> p) async {}

  @override
  Future<void> updateItem(CatalogItem item) async {}

  @override
  Future<void> updateStatus(String id, String status) async {}

  Future<void> close() => _controller.close();
}

CatalogItem _item(String id, String name,
    {String category = 'dress',
    List<String> occasions = const [],
    String status = 'available'}) {
  return CatalogItem(
    id: id,
    name: name,
    category: category,
    occasions: occasions,
    basePrice: 100,
    securityDeposit: 200,
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );
}

Future<HomeViewModel> _readyVm(_FakeInventory repo) async {
  final vm = HomeViewModel(repo);
  repo.emit([
    _item('1', 'Red Gown', category: 'dress', occasions: ['wedding']),
    _item('2', 'Kids Hero Costume', category: 'kiddie', occasions: ['party']),
    _item('3', 'Blue Gown Rented',
        category: 'dress', status: 'rented', occasions: ['wedding']),
  ]);
  // Let the stream listener fire.
  await Future<void>.delayed(Duration.zero);
  return vm;
}

void main() {
  group('HomeViewModel', () {
    test('loads items and counts available', () async {
      final repo = _FakeInventory();
      final vm = await _readyVm(repo);
      expect(vm.isLoading, isFalse);
      expect(vm.items, hasLength(3));
      expect(vm.availableCount, 2);
      vm.dispose();
      await repo.close();
    });

    test('filters by dress / kiddie category', () async {
      final repo = _FakeInventory();
      final vm = await _readyVm(repo);

      vm.selectCategory('dress');
      expect(vm.items.map((e) => e.id), containsAll(['1', '3']));
      expect(vm.items, hasLength(2));

      vm.selectCategory('kiddie');
      expect(vm.items.map((e) => e.id), ['2']);
      vm.dispose();
      await repo.close();
    });

    test('filters by occasion wedding / party', () async {
      final repo = _FakeInventory();
      final vm = await _readyVm(repo);

      vm.selectCategory('wedding');
      expect(vm.items.map((e) => e.id), containsAll(['1', '3']));

      vm.selectCategory('party');
      expect(vm.items.map((e) => e.id), ['2']);
      vm.dispose();
      await repo.close();
    });

    test('search matches name case-insensitively', () async {
      final repo = _FakeInventory();
      final vm = await _readyVm(repo);

      vm.search('hero');
      expect(vm.items.map((e) => e.id), ['2']);

      vm.search('GOWN');
      expect(vm.items, hasLength(2));

      vm.search('');
      expect(vm.items, hasLength(3));
      vm.dispose();
      await repo.close();
    });

    test('search combines with category filter', () async {
      final repo = _FakeInventory();
      final vm = await _readyVm(repo);

      vm.selectCategory('dress');
      vm.search('blue');
      expect(vm.items.map((e) => e.id), ['3']);
      vm.dispose();
      await repo.close();
    });
  });
}
