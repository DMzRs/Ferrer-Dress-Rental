import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';
import 'package:ferrer_rental_shop/features/audit/domain/repositories/audit_repository.dart';

enum LogFilter { all, accounts, rentals, appointments, inventory, auth }

extension LogFilterQuery on LogFilter {
  String get label => switch (this) {
        LogFilter.all => 'All',
        LogFilter.accounts => 'Accounts',
        LogFilter.rentals => 'Rentals',
        LogFilter.appointments => 'Appointments',
        LogFilter.inventory => 'Inventory',
        LogFilter.auth => 'Sign-ups',
      };

  String get prefix => switch (this) {
        LogFilter.all => '',
        LogFilter.accounts => 'account.',
        LogFilter.rentals => 'rental.',
        LogFilter.appointments => 'appointment.',
        LogFilter.inventory => 'item.',
        LogFilter.auth => 'user.',
      };
}

/// Superadmin audit-trail feed with action-group filtering.
class AuditLogViewModel extends ChangeNotifier {
  AuditLogViewModel(AuditRepository repository) : _repository = repository {
    _sub = _repository.watchLogs().listen(
      (entries) {
        _entries = entries;
        _emit();
        notifyListeners();
      },
      // Forward feed errors (e.g. denied reads) so the UI can show them
      // instead of an empty list.
      onError: (Object e) {
        if (!_controller.isClosed) _controller.addError(e);
      },
    );
  }

  final AuditRepository _repository;
  StreamSubscription<List<AuditLogEntry>>? _sub;
  final StreamController<List<AuditLogEntry>> _controller =
      StreamController.broadcast();

  List<AuditLogEntry> _entries = const [];
  LogFilter _filter = LogFilter.all;

  LogFilter get filter => _filter;

  Stream<List<AuditLogEntry>> get entries async* {
    yield _filtered;
    yield* _controller.stream;
  }

  List<AuditLogEntry> get current => List.unmodifiable(_filtered);

  List<AuditLogEntry> get _filtered {
    final prefix = _filter.prefix;
    if (prefix.isEmpty) return _entries;
    return _entries.where((e) => e.action.startsWith(prefix)).toList();
  }

  void setFilter(LogFilter value) {
    if (value == _filter) return;
    _filter = value;
    _emit();
    notifyListeners();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(_filtered);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    super.dispose();
  }
}
