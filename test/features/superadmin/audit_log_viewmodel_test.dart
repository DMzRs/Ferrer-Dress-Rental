import 'package:ferrer_rental_shop/features/audit/data/datasources/mock_audit_data_source.dart';
import 'package:ferrer_rental_shop/features/audit/data/repositories/audit_repository_impl.dart';
import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/viewmodels/audit_log_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filter narrows entries by action group', () async {
    final repo = AuditRepositoryImpl(MockAuditDataSource());
    final now = DateTime(2026, 9, 20);
    for (final action in [
      'user.signup',
      'rental.confirmed',
      'rental.declined',
      'item.created'
    ]) {
      await repo.log(AuditLogEntry(
        id: '',
        actorUid: 'admin-1',
        actorEmail: 'admin@ferrer.ph',
        action: action,
        at: now,
      ));
    }
    final vm = AuditLogViewModel(repo);
    addTearDown(vm.dispose);
    await vm.entries.first;
    vm.setFilter(LogFilter.rentals);
    final filtered = await vm.entries.first;
    expect(filtered, hasLength(2));
    expect(filtered.map((e) => e.action),
        containsAll(['rental.confirmed', 'rental.declined']));
  });
}
