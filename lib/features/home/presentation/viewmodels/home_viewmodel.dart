import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';

/// Streams catalog items and filters by search and category.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._inventoryRepository) {
    _subscription = _inventoryRepository.itemsStream().listen(_onItems);
  }

  final InventoryRepository _inventoryRepository;
  StreamSubscription<List<CatalogItem>>? _subscription;

  /// Filter keys to display labels.
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

  /// Filtered items for the current query and category.
  List<CatalogItem> get items => _filtered;
  /// Whether the catalog stream is still loading.
  bool get isLoading => _loading;
  /// Current search text.
  String get query => _query;
  /// Currently selected category key.
  String get selectedCategory => _selectedCategory;
  /// Number of available items in the catalog.
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

  /// Updates the search query and refreshes results.
  void search(String value) {
    _query = value;
    notifyListeners();
  }

  /// Selects the active category filter.
  void selectCategory(String key) {
    _selectedCategory = key;
    notifyListeners();
  }

  /// Cancels the catalog subscription.
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}


