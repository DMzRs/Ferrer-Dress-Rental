import 'dart:async';

import 'package:ferrer_rental_shop/features/audit/data/datasources/audit_data_source.dart';
import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';

class MockAuditDataSource implements AuditDataSource {
  final List<AuditLogEntry> _entries = [];
  final StreamController<void> _tick =
      StreamController<void>.broadcast();
  int _seq = 0;

  @override
  Stream<List<AuditLogEntry>> watchLogs({int limit = 100}) async* {
    yield _sorted(limit);
    await for (final _ in _tick.stream) {
      yield _sorted(limit);
    }
  }

  @override
  Future<void> log(AuditLogEntry entry) async {
    _entries.add(AuditLogEntry(
      id: 'log-${_seq++}',
      actorUid: entry.actorUid,
      actorEmail: entry.actorEmail,
      action: entry.action,
      targetType: entry.targetType,
      targetId: entry.targetId,
      at: entry.at,
      meta: Map.unmodifiable(entry.meta),
    ));
    if (!_tick.isClosed) _tick.add(null);
  }

  List<AuditLogEntry> _sorted(int limit) {
    final list = [..._entries]
      ..sort((a, b) => b.at.compareTo(a.at));
    return list.take(limit).toList();
  }
}
