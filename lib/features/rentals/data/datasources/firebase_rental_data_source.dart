import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';

import 'package:ferrer_rental_shop/core/constants/firestore_collections.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/data/models/rental_model.dart';
import 'rental_data_source.dart';

class FirebaseRentalDataSource implements RentalDataSource {
  FirebaseFirestore get _db => AppFirestore.instance;

  Query<Map<String, dynamic>> get _base =>
      _db.collection(FirestoreCollections.rentals).orderBy('createdAt', descending: true);

  @override
  Stream<List<Rental>> userRentalsStream(String userId) {
    return _base
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => RentalModel.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Rental>> allRentalsStream() {
    return _base
        .snapshots()
        .map((s) => s.docs.map((d) => RentalModel.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> createRental(Rental rental) async {
    final doc = _db.collection(FirestoreCollections.rentals).doc();
    await doc.set(RentalModel.fromEntity(rental).toMap(forFirestore: true));
  }

  @override
  Future<void> completeRental(String rentalId, {DateTime? returnedAt}) {
    return _db.collection(FirestoreCollections.rentals).doc(rentalId).update({
      'status': 'completed',
      'returnedAt': Timestamp.fromDate(returnedAt ?? DateTime.now()),
    });
  }

  @override
  Future<void> cancelRental(String rentalId) {
    return _db
        .collection(FirestoreCollections.rentals)
        .doc(rentalId)
        .update({'status': 'cancelled'});
  }

  @override
  Future<void> updateRentalStatus(
    String rentalId,
    String status, {
    String? declineReason,
  }) {
    return _db
        .collection(FirestoreCollections.rentals)
        .doc(rentalId)
        .update({
      'status': status,
      if (declineReason != null) 'declineReason': declineReason.trim(),
    });
  }
}

