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

  /// Per-day slot holds live under `slotAvailability/{yyyy-MM-dd}/holds`.
  /// Customers may read holds but only touch their own, so slot checks
  /// never need to read other users' appointments (which rules forbid).
  /// One hold doc per appointment; deleting it frees the slot exactly.
  static String dayDocId(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  CollectionReference<Map<String, dynamic>> _holds(DateTime day) => _db
      .collection(FirestoreCollections.slotAvailability)
      .doc(dayDocId(day))
      .collection('holds');

  /// Loads taken time-slot labels for a calendar day from the holds.
  @override
  Future<List<String>> bookedSlotsFor(DateTime day) async {
    final snapshot = await _holds(day).get();
    final slots = <String>{};
    for (final doc in snapshot.docs) {
      final list = doc.data()['slots'];
      if (list is List) {
        for (final slot in list) {
          final label = slot.toString();
          if (label.isNotEmpty) slots.add(label);
        }
      }
    }
    return slots.toList();
  }

  /// Creates an appointment with its derived time-slot label, plus a hold
  /// doc so the slot reads as taken for everyone.
  @override
  Future<void> createAppointment(Appointment appointment) async {
    final slot = _slotLabel(appointment.scheduledAt);
    final doc = _db.collection(FirestoreCollections.appointments).doc();
    await doc.set(
      AppointmentModel.fromEntity(appointment)
          .toMap(forFirestore: true)
        ..['timeSlot'] = slot,
    );
    await _holds(appointment.scheduledAt).doc(doc.id).set({
      'userId': appointment.userId,
      'slots': [slot],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reads one appointment doc (owner/admin-readable) with its day.
  Future<({DocumentSnapshot<Map<String, dynamic>> doc, DateTime day})?>
      _ownedAppointment(String appointmentId) async {
    final doc = await _db
        .collection(FirestoreCollections.appointments)
        .doc(appointmentId)
        .get();
    if (!doc.exists) return null;
    final scheduledAt = (doc.data()?['scheduledAt'] as Timestamp?)?.toDate();
    if (scheduledAt == null) return null;
    return (doc: doc, day: scheduledAt);
  }

  /// Marks an appointment as cancelled and releases its slot hold.
  @override
  Future<void> cancelAppointment(String appointmentId) async {
    final owned = await _ownedAppointment(appointmentId);
    await _db
        .collection(FirestoreCollections.appointments)
        .doc(appointmentId)
        .update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (owned != null) {
      await _holds(owned.day).doc(appointmentId).delete();
    }
  }

  static const _terminalStatuses = [
    'declined',
    'cancelled',
    'completed',
    'no_show',
  ];

  /// Updates status and optional decline reason. Terminal states release
  /// the slot hold; live states keep it.
  @override
  Future<void> updateStatus(
    String appointmentId,
    String status, {
    String? declineReason,
  }) async {
    final owned = _terminalStatuses.contains(status)
        ? await _ownedAppointment(appointmentId)
        : null;
    await _db
        .collection(FirestoreCollections.appointments)
        .doc(appointmentId)
        .update({
      'status': status,
      if (declineReason != null) 'declineReason': declineReason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (owned != null) {
      await _holds(owned.day).doc(appointmentId).delete();
    }
  }

  String _slotLabel(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $suffix';
  }
}

