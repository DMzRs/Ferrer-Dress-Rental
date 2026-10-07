import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';

/// Pure milestone mapping for the one-time history backfill. No Firebase,
/// no streams — fully unit-testable. The thin executing service feeds it
/// collection snapshots; everything here is deleted after the run except
/// this mapping (kept, tested).
class BackfillPlanner {
  BackfillPlanner._();

  static String keyOf(String action, String targetId) => '$action|$targetId';

  static AuditLogEntry _entry({
    required String actorUid,
    required String actorEmail,
    required String action,
    required String targetType,
    required String targetId,
    required DateTime at,
    Map<String, String> meta = const {},
  }) {
    return AuditLogEntry(
      id: '',
      actorUid: actorUid,
      actorEmail: actorEmail,
      action: action,
      targetType: targetType,
      targetId: targetId,
      at: at,
      meta: {'backfilled': 'true', ...meta},
    );
  }

  /// Raw user docs (`uid` + Firestore fields; `createdAt` may be a
  /// Timestamp, ISO string, or absent).
  static List<AuditLogEntry> planUsers({
    required String actorUid,
    required String actorEmail,
    required List<Map<String, dynamic>> users,
    required Set<String> existingKeys,
  }) {
    final entries = <AuditLogEntry>[];
    for (final doc in users) {
      final uid = (doc['uid'] ?? '').toString();
      if (uid.isEmpty) continue;
      if (existingKeys.contains(keyOf('user.signup', uid))) continue;
      entries.add(_entry(
        actorUid: actorUid,
        actorEmail: actorEmail,
        action: 'user.signup',
        targetType: 'user',
        targetId: uid,
        at: _asDate(doc['createdAt']) ?? DateTime.now(),
        meta: {
          'email': (doc['email'] ?? '').toString(),
          'role': (doc['role'] ?? 'customer').toString(),
        },
      ));
    }
    return entries;
  }

  static List<AuditLogEntry> planRentals({
    required String actorUid,
    required String actorEmail,
    required List<Rental> rentals,
    required Set<String> existingKeys,
  }) {
    final entries = <AuditLogEntry>[];
    void add(String action, Rental r, DateTime at) {
      if (existingKeys.contains(keyOf(action, r.id))) return;
      entries.add(_entry(
        actorUid: actorUid,
        actorEmail: actorEmail,
        action: action,
        targetType: 'rental',
        targetId: r.id,
        at: at,
        meta: {'item': r.itemName},
      ));
    }

    for (final r in rentals) {
      add('rental.requested', r, r.createdAt);
      final touched = r.updatedAt ?? r.createdAt;
      switch (r.status) {
        case 'active':
          add('rental.confirmed', r, touched);
        case 'completed':
          add('rental.confirmed', r, touched);
          add('rental.returned', r,
              r.returnedAt ?? r.updatedAt ?? r.createdAt);
        case 'declined':
          add('rental.declined', r, touched);
        case 'cancelled':
          add('rental.cancelled', r, touched);
      }
    }
    return entries;
  }

  static List<AuditLogEntry> planAppointments({
    required String actorUid,
    required String actorEmail,
    required List<Appointment> appointments,
    required Set<String> existingKeys,
  }) {
    final entries = <AuditLogEntry>[];
    void add(String action, Appointment a, DateTime at) {
      if (existingKeys.contains(keyOf(action, a.id))) return;
      entries.add(_entry(
        actorUid: actorUid,
        actorEmail: actorEmail,
        action: action,
        targetType: 'appointment',
        targetId: a.id,
        at: at,
      ));
    }

    for (final a in appointments) {
      add('appointment.requested', a, a.createdAt);
      final touched = a.updatedAt ?? a.scheduledAt;
      switch (a.status) {
        case Appointment.statusConfirmed:
        case 'scheduled':
          add('appointment.confirmed', a, touched);
        case Appointment.statusDeclined:
          add('appointment.declined', a, touched);
        case Appointment.statusCompleted:
          add('appointment.completed', a, touched);
        case Appointment.statusNoShow:
          add('appointment.no_show', a, touched);
        case Appointment.statusCancelled:
          add('appointment.cancelled', a, touched);
      }
    }
    return entries;
  }

  static List<AuditLogEntry> planItems({
    required String actorUid,
    required String actorEmail,
    required List<CatalogItem> items,
    required Set<String> existingKeys,
  }) {
    final entries = <AuditLogEntry>[];
    for (final item in items) {
      if (existingKeys.contains(keyOf('item.created', item.id))) continue;
      entries.add(_entry(
        actorUid: actorUid,
        actorEmail: actorEmail,
        action: 'item.created',
        targetType: 'item',
        targetId: item.id,
        at: item.createdAt,
        meta: {'name': item.name},
      ));
    }
    return entries;
  }

  static DateTime? _asDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    // Firestore Timestamp without importing cloud_firestore here.
    try {
      final millis = (value as dynamic).millisecondsSinceEpoch as int?;
      if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      // Not a Timestamp — fall through to string parsing.
    }
    return DateTime.tryParse(value.toString());
  }
}
