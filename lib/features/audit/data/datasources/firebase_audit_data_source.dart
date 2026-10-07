import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';
import 'package:ferrer_rental_shop/features/audit/data/datasources/audit_data_source.dart';
import 'package:ferrer_rental_shop/features/audit/data/models/audit_log_model.dart';
import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';

/// Persists and streams audit entries in the auditLogs collection.
class FirebaseAuditDataSource implements AuditDataSource {
  FirebaseFirestore get _db => AppFirestore.instance;

  /// Watches newest-first audit entries up to the given limit.
  @override
  Stream<List<AuditLogEntry>> watchLogs({int limit = 100}) {
    return _db
        .collection('auditLogs')
        .orderBy('at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AuditLogModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Persists a single audit entry.
  @override
  Future<void> log(AuditLogEntry entry) {
    return _db.collection('auditLogs').add(AuditLogModel(
          id: '',
          actorUid: entry.actorUid,
          actorEmail: entry.actorEmail,
          action: entry.action,
          targetType: entry.targetType,
          targetId: entry.targetId,
          at: entry.at,
          meta: entry.meta,
        ).toMap());
  }
}
