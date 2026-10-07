import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';

abstract class AuditRepository {
  /// Newest-first audit feed for the superadmin Logs tab.
  Stream<List<AuditLogEntry>> watchLogs({int limit = 100});

  Future<void> log(AuditLogEntry entry);
}
