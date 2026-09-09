import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';

import 'package:ferrer_rental_shop/core/constants/firestore_collections.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/data/models/catalog_item_model.dart';
import 'item_data_source.dart';

class FirebaseItemDataSource implements ItemDataSource {
  FirebaseFirestore get _db => AppFirestore.instance;

  @override
  Stream<List<CatalogItem>> itemsStream() {
    return _db
        .collection(FirestoreCollections.items)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CatalogItemModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<String> addItem(CatalogItem item) async {
    final doc = _db.collection(FirestoreCollections.items).doc();
    await doc.set(CatalogItemModel.fromEntity(item).toMap(forFirestore: true));
    return doc.id;
  }

  @override
  Future<void> updateItem(CatalogItem item) {
    return _db
        .collection(FirestoreCollections.items)
        .doc(item.id)
        .update(CatalogItemModel.fromEntity(item).toMap(forFirestore: true));
  }

  @override
  Future<void> updateStatus(String itemId, String status) {
    return _db
        .collection(FirestoreCollections.items)
        .doc(itemId)
        .update({'status': status});
  }

  @override
  Future<void> saveItemPhotos(String itemId, List<String> photos) async {
    final ref = _db.collection(FirestoreCollections.itemPhotos).doc(itemId);
    if (photos.isEmpty) {
      // All photos were removed in edit mode — drop the side doc entirely
      // so stale photos don't keep showing on the details screen.
      await ref.delete();
      return;
    }
    await ref.set({'photos': photos, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<List<String>> itemPhotos(String itemId) async {
    final doc =
        await _db.collection(FirestoreCollections.itemPhotos).doc(itemId).get();
    if (!doc.exists) return const [];
    final photos = doc.data()?['photos'];
    if (photos is List) return photos.map((e) => e.toString()).toList();
    return const [];
  }
}

