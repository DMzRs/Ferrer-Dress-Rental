import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';
import 'package:ferrer_rental_shop/features/audit/data/datasources/audit_data_source.dart';
import 'package:ferrer_rental_shop/features/audit/data/models/audit_log_model.dart';
import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';

class FirebaseAuditDataSource implements AuditDataSource {
  FirebaseFirestore get _db => AppFirestore.instance;

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
