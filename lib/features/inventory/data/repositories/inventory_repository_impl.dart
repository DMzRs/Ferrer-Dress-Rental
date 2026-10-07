import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/data/datasources/firebase_item_data_source.dart';
import 'package:ferrer_rental_shop/features/inventory/data/datasources/item_data_source.dart';
import 'package:ferrer_rental_shop/features/inventory/data/datasources/mock_item_data_source.dart';

/// Routes inventory calls to the active item data source.
class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._dataSource);

  final ItemDataSource _dataSource;

  /// Returns the Firebase or mock source per app config.
  static ItemDataSource defaultDataSource() =>
      AppConfig.firebaseEnabled ? FirebaseItemDataSource() : MockItemDataSource();

  /// Streams catalog items from the data source.
  @override
  Stream<List<CatalogItem>> itemsStream() => _dataSource.itemsStream();

  /// Adds an item through the data source.
  @override
  Future<String> addItem(CatalogItem item) => _dataSource.addItem(item);

  /// Updates an item through the data source.
  @override
  Future<void> updateItem(CatalogItem item) => _dataSource.updateItem(item);

  /// Updates an item status through the data source.
  @override
  Future<void> updateStatus(String itemId, String status) =>
      _dataSource.updateStatus(itemId, status);

  /// Saves item photos through the data source.
  @override
  Future<void> saveItemPhotos(String itemId, List<String> photos) =>
      _dataSource.saveItemPhotos(itemId, photos);

  /// Loads item photos through the data source.
  @override
  Future<List<String>> itemPhotos(String itemId) =>
      _dataSource.itemPhotos(itemId);
}

