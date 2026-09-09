import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';

import 'package:ferrer_rental_shop/core/constants/firestore_collections.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/data/models/appointment_model.dart';
import 'appointment_data_source.dart';

class FirebaseAppointmentDataSource implements AppointmentDataSource {
  FirebaseFirestore get _db => AppFirestore.instance;

  Query<Map<String, dynamic>> get _base => _db
      .collection(FirestoreCollections.appointments)
      .orderBy('scheduledAt', descending: true);

  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) {
    return _base
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AppointmentModel.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Appointment>> allAppointmentsStream() {
    return _base
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AppointmentModel.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<List<String>> bookedSlotsFor(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final snapshot = await _db
        .collection(FirestoreCollections.appointments)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(end))
        .get();
    return snapshot.docs.map((d) => (d.data()['timeSlot'] ?? '') as String).toList();
  }

  @override
  Future<void> createAppointment(Appointment appointment) async {
    final doc = _db.collection(FirestoreCollections.appointments).doc();
    await doc.set(
      AppointmentModel.fromEntity(appointment)
          .toMap(forFirestore: true)
        ..['timeSlot'] = _slotLabel(appointment.scheduledAt),
    );
  }

  @override
  Future<void> cancelAppointment(String appointmentId) {
    return _db
        .collection(FirestoreCollections.appointments)
        .doc(appointmentId)
        .update({'status': 'cancelled'});
  }

  @override
  Future<void> updateStatus(
    String appointmentId,
    String status, {
    String? declineReason,
  }) {
    return _db
        .collection(FirestoreCollections.appointments)
        .doc(appointmentId)
        .update({
      'status': status,
      if (declineReason != null) 'declineReason': declineReason.trim(),
    });
  }

  String _slotLabel(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $suffix';
  }
}

