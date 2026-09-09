import 'package:ferrer_rental_shop/features/booking/data/models/appointment_model.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentModel.fromMap', () {
    test('parses full map', () {
      final m = AppointmentModel.fromMap('a1', {
        'userId': 'u1',
        'userName': 'Jane',
        'itemId': 'i1',
        'itemName': 'Gown',
        'purpose': 'Trying On',
        'scheduledAt': DateTime(2026, 9, 10, 10),
        'status': 'pending',
        'createdAt': DateTime(2026, 9, 1),
      });
      expect(m.id, 'a1');
      expect(m.itemId, 'i1');
      expect(m.purpose, 'Trying On');
      expect(m.status, Appointment.statusPending);
    });

    test('defaults missing optionals and status', () {
      final m = AppointmentModel.fromMap('a2', {});
      expect(m.itemId, isNull);
      expect(m.itemName, isNull);
      expect(m.purpose, 'Measuring');
      expect(m.declineReason, '');
    });

    test('parses ISO date strings', () {
      final m = AppointmentModel.fromMap('a3', {
        'scheduledAt': '2026-09-10T10:00:00.000',
        'createdAt': '2026-09-01T00:00:00.000',
      });
      expect(m.scheduledAt, DateTime(2026, 9, 10, 10));
    });
  });

  group('AppointmentModel mapping', () {
    test('fromEntity copies fields', () {
      final src = AppointmentModel.fromMap('a4', {
        'userId': 'u1',
        'userName': 'Jane',
        'purpose': 'Measuring',
        'scheduledAt': DateTime(2026, 9, 10),
        'status': 'confirmed',
        'createdAt': DateTime(2026, 9, 1),
      });
      final copy = AppointmentModel.fromEntity(src);
      expect(copy.id, 'a4');
      expect(copy.status, 'confirmed');
    });

    test('copyWith can clear item and decline reason', () {
      final src = AppointmentModel.fromMap('a5', {
        'userId': 'u1',
        'userName': 'Jane',
        'itemId': 'i1',
        'itemName': 'Gown',
        'purpose': 'Measuring',
        'scheduledAt': DateTime(2026, 9, 10),
        'status': 'declined',
        'declineReason': 'No slot',
        'createdAt': DateTime(2026, 9, 1),
      });
      final cleared = src.copyWith(clearItem: true, clearDeclineReason: true);
      expect(cleared.itemId, isNull);
      expect(cleared.itemName, isNull);
      expect(cleared.declineReason, '');
      expect(src.copyWith(status: 'confirmed').status, 'confirmed');
    });

    test('toMap round-trips and omits nulls/empty reason', () {
      final src = AppointmentModel.fromMap('a6', {
        'userId': 'u1',
        'userName': 'Jane',
        'purpose': 'Measuring',
        'scheduledAt': DateTime(2026, 9, 10, 9),
        'status': 'pending',
        'createdAt': DateTime(2026, 9, 1),
      });
      final map = src.toMap();
      expect(map.containsKey('itemId'), isFalse);
      expect(map.containsKey('declineReason'), isFalse);
      final rt = AppointmentModel.fromMap('a6', map);
      expect(rt.purpose, 'Measuring');

      final withReason = src.copyWith(declineReason: 'Full');
      expect(withReason.toMap()['declineReason'], 'Full');
    });
  });
}
