import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:flutter_test/flutter_test.dart';

Rental _rental({
  String status = 'active',
  DateTime? start,
  DateTime? end,
}) {
  final now = DateTime.now();
  return Rental(
    id: 'r1',
    userId: 'u1',
    userName: 'Jane Doe',
    itemId: 'i1',
    itemName: 'Gown',
    startDate: start ?? now.subtract(const Duration(days: 1)),
    endDate: end ?? now.add(const Duration(days: 2)),
    rentalFee: 500,
    securityDeposit: 1000,
    total: 1500,
    status: status,
    createdAt: now,
  );
}

void main() {
  group('Rental status flags', () {
    test('isActive / isCompleted / isCancelled', () {
      expect(_rental(status: 'active').isActive, isTrue);
      expect(_rental(status: 'completed').isCompleted, isTrue);
      expect(_rental(status: 'cancelled').isCancelled, isTrue);
      expect(_rental(status: 'active').isCompleted, isFalse);
    });

    test('isPending / isDeclined', () {
      expect(_rental(status: 'pending').isPending, isTrue);
      expect(_rental(status: 'pending').isActive, isFalse);
      expect(_rental(status: 'declined').isDeclined, isTrue);
    });

    test('isOverdue only for active rentals past end-of-day', () {
      final now = DateTime.now();
      final overdue = _rental(
        start: now.subtract(const Duration(days: 5)),
        end: now.subtract(const Duration(days: 1)),
      );
      expect(overdue.isOverdue, isTrue);

      final upcoming = _rental(
        start: now,
        end: now.add(const Duration(days: 3)),
      );
      expect(upcoming.isOverdue, isFalse);

      // Completed rentals are never overdue even if past end date.
      final completedPast = _rental(
        status: 'completed',
        start: now.subtract(const Duration(days: 5)),
        end: now.subtract(const Duration(days: 1)),
      );
      expect(completedPast.isOverdue, isFalse);
    });

    test('displayStatus maps overdue correctly', () {
      final now = DateTime.now();
      expect(_rental(status: 'completed').displayStatus, 'completed');
      expect(_rental(status: 'cancelled').displayStatus, 'cancelled');
      expect(_rental(status: 'pending').displayStatus, 'pending');
      expect(_rental(status: 'declined').displayStatus, 'declined');
      expect(
        _rental(
          start: now.subtract(const Duration(days: 5)),
          end: now.subtract(const Duration(days: 1)),
        ).displayStatus,
        'overdue',
      );
      expect(
        _rental(
          start: now,
          end: now.add(const Duration(days: 1)),
        ).displayStatus,
        'active',
      );
    });
  });

  group('Rental date math', () {
    test('totalDays is inclusive and minimum 1', () {
      final r = _rental(
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 10),
      );
      expect(r.totalDays, 4);

      final sameDay = _rental(
        start: DateTime(2026, 9, 7),
        end: DateTime(2026, 9, 7),
      );
      expect(sameDay.totalDays, 1);
    });

    test('daysElapsed clamps to [0, totalDays]', () {
      final now = DateTime.now();
      final ongoing = _rental(
        start: now.subtract(const Duration(days: 2)),
        end: now.add(const Duration(days: 2)),
      );
      expect(ongoing.daysElapsed, 2);
      expect(ongoing.daysRemaining, ongoing.totalDays - 2);

      final future = _rental(
        start: now.add(const Duration(days: 5)),
        end: now.add(const Duration(days: 7)),
      );
      expect(future.daysElapsed, 0);
      expect(future.daysRemaining, future.totalDays);
    });

    test('progress is 1 when completed, else elapsed/total', () {
      expect(_rental(status: 'completed').progress, 1);
      final now = DateTime.now();
      final r = _rental(
        start: now.subtract(const Duration(days: 1)),
        end: now.add(const Duration(days: 3)),
      );
      expect(r.progress, inInclusiveRange(0.0, 1.0));
    });
  });
}
