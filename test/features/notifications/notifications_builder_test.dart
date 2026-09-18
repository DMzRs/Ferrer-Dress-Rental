import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/notifications/domain/app_notification.dart';
import 'package:ferrer_rental_shop/features/notifications/domain/notifications_builder.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:flutter_test/flutter_test.dart';

Rental _rental({required String id, required String status, required DateTime end, DateTime? created}) =>
    Rental(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Gown',
      startDate: end.subtract(const Duration(days: 4)),
      endDate: end,
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: status,
      createdAt: created ?? DateTime(2026, 8, 1),
    );

Appointment _appt({required String id, required String status, required DateTime at}) =>
    Appointment(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      purpose: 'Trying On',
      scheduledAt: at,
      status: status,
      createdAt: DateTime(2026, 8, 1),
    );

void main() {
  test('maps rentals to events, overdue first by recency', () {
    final now = DateTime.now();
    final list = buildNotifications(
      [
        _rental(id: 'old-done', status: 'completed', end: now.subtract(const Duration(days: 30)), created: DateTime(2026, 7, 1)),
        _rental(id: 'over-1', status: 'active', end: now.subtract(const Duration(days: 1))),
        _rental(id: 'pend-1', status: 'pending', end: now.add(const Duration(days: 3))),
      ],
      const [],
    );
    expect(list.map((n) => n.id), ['rental:over-1:overdue', 'rental:pend-1:pending', 'rental:old-done:returned']);
    expect(list.first.kind, NotificationKind.overdue);
    expect(list.first.attention, isTrue);
    expect(list.last.attention, isFalse);
  });

  test('due-soon and upcoming appointments flag attention', () {
    final now = DateTime.now();
    final list = buildNotifications(
      [_rental(id: 'due-1', status: 'active', end: now.add(const Duration(days: 1)))],
      [_appt(id: 'a1', status: 'confirmed', at: now.add(const Duration(hours: 5)))],
    );
    expect(list.where((n) => n.attention).length, 2);
    expect(
      list.map((n) => n.kind),
      containsAll([NotificationKind.dueSoon, NotificationKind.appointmentSoon]),
    );
  });

  test('declined items are info rows, cancelled are skipped', () {
    final now = DateTime.now();
    final list = buildNotifications(
      [
        _rental(id: 'dec-1', status: 'declined', end: now.add(const Duration(days: 1))),
        _rental(id: 'can-1', status: 'cancelled', end: now.add(const Duration(days: 1))),
      ],
      [_appt(id: 'a2', status: 'cancelled', at: now.add(const Duration(days: 1)))],
    );
    expect(list.map((n) => n.id), ['rental:dec-1:declined']);
    expect(list.single.attention, isFalse);
  });

  test('attentionCount sums actionable items only', () {
    final now = DateTime.now();
    final list = buildNotifications(
      [
        _rental(id: 'over-1', status: 'active', end: now.subtract(const Duration(days: 1))),
        _rental(id: 'pend-1', status: 'pending', end: now.add(const Duration(days: 3))),
        _rental(id: 'done-1', status: 'completed', end: now.subtract(const Duration(days: 9))),
      ],
      [_appt(id: 'a1', status: 'confirmed', at: now.add(const Duration(hours: 5)))],
    );
    expect(attentionCount(list), 2);
  });
}
