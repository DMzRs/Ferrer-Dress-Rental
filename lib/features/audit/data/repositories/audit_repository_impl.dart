import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/features/audit/data/datasources/audit_data_source.dart';
import 'package:ferrer_rental_shop/features/audit/data/datasources/firebase_audit_data_source.dart';
import 'package:ferrer_rental_shop/features/audit/data/datasources/mock_audit_data_source.dart';
import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';
import 'package:ferrer_rental_shop/features/audit/domain/repositories/audit_repository.dart';

/// Delegates audit reads and writes to the configured data source.
class AuditRepositoryImpl implements AuditRepository {
  const AuditRepositoryImpl(this._dataSource);

  final AuditDataSource _dataSource;

  /// Picks the Firebase or in-memory audit source from app config.
  static AuditDataSource defaultDataSource() => AppConfig.firebaseEnabled
      ? FirebaseAuditDataSource()
      : MockAuditDataSource();

  /// Watches newest-first audit entries up to the given limit.
  @override
  Stream<List<AuditLogEntry>> watchLogs({int limit = 100}) =>
      _dataSource.watchLogs(limit: limit);

  /// Persists a single audit entry.
  @override
  Future<void> log(AuditLogEntry entry) => _dataSource.log(entry);
}
