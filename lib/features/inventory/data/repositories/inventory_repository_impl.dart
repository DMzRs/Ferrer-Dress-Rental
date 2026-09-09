import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/data/datasources/firebase_item_data_source.dart';
import 'package:ferrer_rental_shop/features/inventory/data/datasources/item_data_source.dart';
import 'package:ferrer_rental_shop/features/inventory/data/datasources/mock_item_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._dataSource);

  final ItemDataSource _dataSource;

  static ItemDataSource defaultDataSource() =>
      AppConfig.firebaseEnabled ? FirebaseItemDataSource() : MockItemDataSource();

  @override
  Stream<List<CatalogItem>> itemsStream() => _dataSource.itemsStream();

  @override
  Future<String> addItem(CatalogItem item) => _dataSource.addItem(item);

  @override
  Future<void> updateItem(CatalogItem item) => _dataSource.updateItem(item);

  @override
  Future<void> updateStatus(String itemId, String status) =>
      _dataSource.updateStatus(itemId, status);

  @override
  Future<void> saveItemPhotos(String itemId, List<String> photos) =>
      _dataSource.saveItemPhotos(itemId, photos);

  @override
  Future<List<String>> itemPhotos(String itemId) =>
      _dataSource.itemPhotos(itemId);
}

