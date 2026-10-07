import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';

/// Streams audit entries and persists new log records.
abstract class AuditDataSource {
/// Watches newest-first audit entries up to the given limit.
  Stream<List<AuditLogEntry>> watchLogs({int limit = 100});

/// Persists a single audit entry.
  Future<void> log(AuditLogEntry entry);
}
