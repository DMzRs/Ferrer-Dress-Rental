import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';

class ItemDetailsViewModel extends ChangeNotifier {
  ItemDetailsViewModel(this.item, this._inventoryRepository) {
    _loadPhotos();
  }

  final CatalogItem item;
  final InventoryRepository _inventoryRepository;

  String? selectedSize;
  int currentPage = 0;

  List<String> _photos = const [];

  /// Full photos loaded from itemPhotos/{id}; falls back to the doc's
  /// thumbnail until (or unless) the side doc has more.
  List<String> get photos {
    if (_photos.isNotEmpty) return _photos;
    return item.thumbnail.isEmpty ? const [] : [item.thumbnail];
  }

  Future<void> _loadPhotos() async {
    if (item.id.isEmpty) return;
    try {
      final photos = await _inventoryRepository.itemPhotos(item.id);
      if (photos.isEmpty) return;
      _photos = photos;
      notifyListeners();
    } on Object {
      // Details still render with the thumbnail.
    }
  }

  bool get needsSize => item.sizes.isNotEmpty;
  bool get canRent => !needsSize || selectedSize != null;

  void selectSize(String size) {
    selectedSize = size;
    notifyListeners();
  }

  void setPage(int index) {
    currentPage = index;
    notifyListeners();
  }
}
