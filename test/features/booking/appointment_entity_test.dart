import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:flutter_test/flutter_test.dart';

Appointment _appt({String status = 'pending', DateTime? scheduledAt}) {
  return Appointment(
    id: 'a1',
    userId: 'u1',
    userName: 'Jane',
    purpose: 'Measuring',
    scheduledAt: scheduledAt ?? DateTime.now().add(const Duration(days: 1)),
    status: status,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('Appointment.isUpcoming', () {
    test('pending/confirmed/scheduled in future are upcoming', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(_appt(status: 'pending', scheduledAt: future).isUpcoming, isTrue);
      expect(_appt(status: 'confirmed', scheduledAt: future).isUpcoming, isTrue);
      expect(_appt(status: 'scheduled', scheduledAt: future).isUpcoming, isTrue);
    });

    test('past appointments are not upcoming', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(_appt(status: 'pending', scheduledAt: past).isUpcoming, isFalse);
    });

    test('declined/cancelled are never upcoming', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(_appt(status: 'declined', scheduledAt: future).isUpcoming, isFalse);
      expect(
        _appt(status: 'cancelled', scheduledAt: future).isUpcoming,
        isFalse,
      );
    });
  });

  group('Appointment.isPast', () {
    test('true when scheduledAt is before now', () {
      expect(
        _appt(scheduledAt: DateTime.now().subtract(const Duration(hours: 1)))
            .isPast,
        isTrue,
      );
      expect(
        _appt(scheduledAt: DateTime.now().add(const Duration(hours: 1))).isPast,
        isFalse,
      );
    });
  });

  group('Appointment.statusLabel', () {
    test('maps lifecycle statuses', () {
      expect(_appt(status: 'pending').statusLabel, 'Pending');
      expect(_appt(status: 'confirmed').statusLabel, 'Scheduled');
      expect(_appt(status: 'scheduled').statusLabel, 'Scheduled');
      expect(_appt(status: 'declined').statusLabel, 'Declined');
      expect(_appt(status: 'cancelled').statusLabel, 'Cancelled');
    });

    test('returns raw status for unknown values', () {
      expect(_appt(status: 'mystery').statusLabel, 'mystery');
    });
  });

  test('purposes contains Measuring and Trying On', () {
    expect(Appointment.purposes, containsAll(['Measuring', 'Trying On']));
  });
}
