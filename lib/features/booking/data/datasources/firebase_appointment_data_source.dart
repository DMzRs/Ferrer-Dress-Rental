import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';

import 'package:ferrer_rental_shop/core/constants/firestore_collections.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/data/models/appointment_model.dart';
import 'appointment_data_source.dart';

/// Firestore-backed appointment store ordered by schedule.
class FirebaseAppointmentDataSource implements AppointmentDataSource {
  FirebaseFirestore get _db => AppFirestore.instance;

  Query<Map<String, dynamic>> get _base => _db
      .collection(FirestoreCollections.appointments)
      .orderBy('scheduledAt', descending: true);

  /// Streams appointments for one user newest first.
  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) {
    return _base
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AppointmentModel.fromMap(d.id, d.data())).toList());
  }

  /// Streams all appointments newest first.
  @override
  Stream<List<Appointment>> allAppointmentsStream() {
    return _base
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AppointmentModel.fromMap(d.id, d.data())).toList());
  }

  /// Streams the most recent appointments up to [limit].
  @override
  Stream<List<Appointment>> pagedAppointmentsStream({int limit = 20}) {
    return _base
        .limit(limit)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AppointmentModel.fromMap(d.id, d.data())).toList());
  }

  /// Loads taken time-slot labels for a calendar day.
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

  /// Creates an appointment with its derived time-slot label.
  @override
  Future<void> createAppointment(Appointment appointment) async {
    final doc = _db.collection(FirestoreCollections.appointments).doc();
    await doc.set(
      AppointmentModel.fromEntity(appointment)
          .toMap(forFirestore: true)
        ..['timeSlot'] = _slotLabel(appointment.scheduledAt),
    );
  }

  /// Marks an appointment as cancelled.
  @override
  Future<void> cancelAppointment(String appointmentId) {
    return _db
        .collection(FirestoreCollections.appointments)
        .doc(appointmentId)
        .update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates status and optional decline reason.
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _slotLabel(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $suffix';
  }
}

