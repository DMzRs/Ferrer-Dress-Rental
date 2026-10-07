import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';

abstract class AuditDataSource {
  Stream<List<AuditLogEntry>> watchLogs({int limit = 100});

  Future<void> log(AuditLogEntry entry);
}
