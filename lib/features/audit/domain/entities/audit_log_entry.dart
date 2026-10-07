/// One audit-trail row. Written client-side at the call site for
/// account, rental, appointment, and inventory decisions. Best-effort:
/// logging never blocks the action it records.
class AuditLogEntry {
  final String id;
  final String actorUid;
  final String actorEmail;
  final String action;
  final String targetType;
  final String targetId;
  final DateTime at;
  final Map<String, String> meta;

  const AuditLogEntry({
    required this.id,
    required this.actorUid,
    required this.actorEmail,
    required this.action,
    this.targetType = '',
    this.targetId = '',
    required this.at,
    this.meta = const {},
  });
}
