import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/backfill/backfill_planner.dart';
import 'package:flutter_test/flutter_test.dart';

Rental _rental({required String id, required String status}) => Rental(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Gown',
      startDate: DateTime(2026, 9, 18),
      endDate: DateTime(2026, 9, 20),
      rentalFee: 500,
      securityDeposit: 200,
      total: 700,
      status: status,
      createdAt: DateTime(2026, 9, 17),
      updatedAt:
          status == 'pending' ? null : DateTime(2026, 9, 19),
      returnedAt:
          status == 'completed' ? DateTime(2026, 9, 25) : null,
    );

Appointment _appointment({required String id, required String status}) =>
    Appointment(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      purpose: 'Fitting',
      scheduledAt: DateTime(2026, 9, 20),
      status: status,
      createdAt: DateTime(2026, 9, 15),
      updatedAt: status == 'pending' ? null : DateTime(2026, 9, 18),
    );

void main() {
  test('rental milestones follow status and dates', () {
    final plan = BackfillPlanner.planRentals(
      actorUid: 's1',
      actorEmail: 'owner@x.com',
      rentals: [
        _rental(id: 'r-pending', status: 'pending'),
        _rental(id: 'r-active', status: 'active'),
        _rental(id: 'r-done', status: 'completed'),
        _rental(id: 'r-nope', status: 'declined'),
      ],
      existingKeys: const {},
    );
    List<String> actions(String id) => plan
        .where((e) => e.targetId == id)
        .map((e) => e.action)
        .toList();
    expect(actions('r-pending'), ['rental.requested']);
    expect(actions('r-active'), ['rental.requested', 'rental.confirmed']);
    expect(actions('r-done'),
        ['rental.requested', 'rental.confirmed', 'rental.returned']);
    expect(actions('r-nope'), ['rental.requested', 'rental.declined']);
    // Historical dates preserved, importer stamped as actor.
    final done = plan.firstWhere((e) =>
        e.targetId == 'r-done' && e.action == 'rental.returned');
    expect(done.at, DateTime(2026, 9, 25));
    expect(done.actorUid, 's1');
    expect(done.meta['backfilled'], 'true');
  });

  test('existing entries are skipped for idempotent reruns', () {
    final plan = BackfillPlanner.planRentals(
      actorUid: 's1',
      actorEmail: 'owner@x.com',
      rentals: [_rental(id: 'r-pending', status: 'pending')],
      existingKeys: const {'rental.requested|r-pending'},
    );
    expect(plan, isEmpty);
  });

  test('appointment milestones follow status', () {
    final plan = BackfillPlanner.planAppointments(
      actorUid: 's1',
      actorEmail: 'owner@x.com',
      appointments: [
        _appointment(id: 'a-pending', status: 'pending'),
        _appointment(id: 'a-nope', status: 'declined'),
        _appointment(id: 'a-done', status: 'completed'),
      ],
      existingKeys: const {},
    );
    List<String> actions(String id) => plan
        .where((e) => e.targetId == id)
        .map((e) => e.action)
        .toList();
    expect(actions('a-pending'), ['appointment.requested']);
    expect(actions('a-nope'),
        ['appointment.requested', 'appointment.declined']);
    expect(actions('a-done'),
        ['appointment.requested', 'appointment.completed']);
  });
}
