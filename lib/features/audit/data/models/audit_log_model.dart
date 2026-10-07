import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';

class AuditLogModel extends AuditLogEntry {
  const AuditLogModel({
    required super.id,
    required super.actorUid,
    required super.actorEmail,
    required super.action,
    super.targetType,
    super.targetId,
    required super.at,
    super.meta,
  });

  factory AuditLogModel.fromMap(String id, Map<String, dynamic> map) {
    final at = map['at'];
    return AuditLogModel(
      id: id,
      actorUid: (map['actorUid'] ?? '') as String,
      actorEmail: (map['actorEmail'] ?? '') as String,
      action: (map['action'] ?? '') as String,
      targetType: (map['targetType'] ?? '') as String,
      targetId: (map['targetId'] ?? '') as String,
      at: at is Timestamp
          ? at.toDate()
          : DateTime.tryParse(at?.toString() ?? '') ?? DateTime.now(),
      meta: ((map['meta'] as Map?) ?? {})
          .map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'actorUid': actorUid,
      'actorEmail': actorEmail,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'at': Timestamp.fromDate(at),
      'meta': meta,
    };
  }
}
