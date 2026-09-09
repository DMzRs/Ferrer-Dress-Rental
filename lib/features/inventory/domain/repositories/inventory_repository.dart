import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';

abstract class InventoryRepository {
  Stream<List<CatalogItem>> itemsStream();

  /// Creates the item and returns its new id.
  Future<String> addItem(CatalogItem item);

  Future<void> updateItem(CatalogItem item);

  Future<void> updateStatus(String itemId, String status);

  /// Saves the item's full-size photos (data URIs) in a side doc.
  Future<void> saveItemPhotos(String itemId, List<String> photos);

  /// Returns the item's full-size photos, or an empty list when none.
  Future<List<String>> itemPhotos(String itemId);
}

