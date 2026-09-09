import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._inventoryRepository) {
    _subscription = _inventoryRepository.itemsStream().listen(_onItems);
  }

  final InventoryRepository _inventoryRepository;
  StreamSubscription<List<CatalogItem>>? _subscription;

  static const Map<String, String> categories = {
    'all': 'All',
    'dress': 'Adult Dresses',
    'kiddie': 'Kiddie Costumes',
    'wedding': 'Wedding',
    'party': 'Party',
  };

  List<CatalogItem> _items = [];
  bool _loading = true;
  String _query = '';
  String _selectedCategory = 'all';

  List<CatalogItem> get items => _filtered;
  bool get isLoading => _loading;
  String get query => _query;
  String get selectedCategory => _selectedCategory;
  int get availableCount => _items.where((i) => i.isAvailable).length;

  void _onItems(List<CatalogItem> items) {
    _items = items;
    _loading = false;
    notifyListeners();
  }

  List<CatalogItem> get _filtered {
    Iterable<CatalogItem> result = _items;
    switch (_selectedCategory) {
      case 'dress':
      case 'kiddie':
        result = result.where((i) => i.category == _selectedCategory);
        break;
      case 'wedding':
      case 'party':
        result =
            result.where((i) => i.occasions.contains(_selectedCategory));
        break;
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((i) =>
          i.name.toLowerCase().contains(q) ||
          i.categoryLabel.toLowerCase().contains(q) ||
          i.occasions.any((o) => o.toLowerCase().contains(q)));
    }
    return result.toList();
  }

  void search(String value) {
    _query = value;
    notifyListeners();
  }

  void selectCategory(String key) {
    _selectedCategory = key;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}


