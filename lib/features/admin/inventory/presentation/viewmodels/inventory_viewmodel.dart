import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/core/services/item_photo_encoder.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryViewModel extends ChangeNotifier {
  InventoryViewModel(this._repository) {
    _subscription = _repository.itemsStream().listen(_onItems);
  }

  final InventoryRepository _repository;
  StreamSubscription<List<CatalogItem>>? _subscription;

  List<CatalogItem> _items = [];
  bool _loading = true;
  String? _busyItemId;
  String _query = '';

  List<CatalogItem> get items {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where((i) => i.name.toLowerCase().contains(q))
        .toList();
  }

  bool get isLoading => _loading;
  String? get busyItemId => _busyItemId;

  int get availableCount => _items.where((i) => i.isAvailable).length;
  int get rentedCount => _items.where((i) => i.status == 'rented').length;
  int get scheduledCount =>
      _items.where((i) => i.status == 'scheduled_for_appointment').length;
  int get maintenanceCount =>
      _items.where((i) => i.status == 'maintenance').length;

  void _onItems(List<CatalogItem> items) {
    _items = items;
    _loading = false;
    notifyListeners();
  }

  void search(String value) {
    _query = value;
    notifyListeners();
  }

  Future<bool> changeStatus(CatalogItem item, String status) async {
    if (item.status == status) return true;
    _busyItemId = item.id;
    notifyListeners();
    try {
      await _repository.updateStatus(item.id, status);
      return true;
    } catch (_) {
      return false;
    } finally {
      _busyItemId = null;
      notifyListeners();
    }
  }

  /// Creates the item (with its thumbnail) and stores its full photos.
  /// Returns the new item id, or null when something failed.
  Future<String?> addItem({
    required String name,
    required String category,
    required String description,
    required double basePrice,
    required double securityDeposit,
    required List<String> sizes,
    required List<String> occasions,
    required List<File> photos,
  }) async {
    try {
      final bundle =
          photos.isEmpty ? null : await ItemPhotoEncoder.encode(photos);
      final id = await _repository.addItem(
        CatalogItem(
          id: '',
          name: name,
          description: description,
          category: category,
          occasions: occasions,
          basePrice: basePrice,
          securityDeposit: securityDeposit,
          sizes: sizes,
          thumbnail: bundle?.thumbnail ?? '',
          status: 'available',
          createdAt: DateTime.now(),
        ),
      );
      if (bundle != null) {
        await _repository.saveItemPhotos(id, bundle.photos);
      }
      return id;
    } on PhotoTooLargeException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// Applies text-field edits and, when photos were touched, rebuilds the
  /// photo doc (kept existing + newly added) and the item's thumbnail.
  Future<bool> updateItem({
    required CatalogItem item,
    required List<File> newPhotos,
    required List<String> keptPhotos,
    required bool photosChanged,
  }) async {
    try {
      var updated = item;
      if (photosChanged) {
        final bundle =
            newPhotos.isEmpty ? null : await ItemPhotoEncoder.encode(newPhotos);
        final finalPhotos = [...keptPhotos, ...?bundle?.photos];
        var thumbnail = '';
        if (finalPhotos.isNotEmpty) {
          thumbnail = await ItemPhotoEncoder.thumbnailFor(finalPhotos.first);
        }
        updated = item.copyWith(thumbnail: thumbnail);
        await _repository.updateItem(updated);
        await _repository.saveItemPhotos(item.id, finalPhotos);
      } else {
        await _repository.updateItem(updated);
      }
      return true;
    } on PhotoTooLargeException {
      rethrow;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> itemPhotos(String itemId) =>
      _repository.itemPhotos(itemId);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}


