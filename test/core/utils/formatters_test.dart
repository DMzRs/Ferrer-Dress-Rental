import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.peso', () {
    test('formats whole amounts with peso sign', () {
      expect(Formatters.peso(1000), '₱1,000');
    });

    test('formats decimals up to 2 places', () {
      expect(Formatters.peso(99.5), '₱99.5');
      expect(Formatters.peso(1500.75), '₱1,500.75');
    });

    test('formats zero', () {
      expect(Formatters.peso(0), '₱0');
    });
  });

  group('Formatters dates', () {
    test('date formats as MMM d, yyyy', () {
      expect(Formatters.date(DateTime(2026, 1, 5)), 'Jan 5, 2026');
    });

    test('shortDate formats as MMM d', () {
      expect(Formatters.shortDate(DateTime(2026, 12, 25)), 'Dec 25');
    });

    test('monthDay formats as EEE, MMM d', () {
      final d = DateTime(2026, 9, 7); // Monday
      expect(Formatters.monthDay(d), 'Mon, Sep 7');
    });

    test('range combines start and end', () {
      final range = Formatters.range(DateTime(2026, 9, 7), DateTime(2026, 9, 10));
      expect(range, 'Sep 7 – Sep 10, 2026');
    });

    test('monthYear formats as MMMM yyyy', () {
      expect(Formatters.monthYear(DateTime(2026, 2, 1)), 'February 2026');
    });
  });

  group('Formatters.timeAgo', () {
    test('returns Just now for < 1 minute', () {
      expect(Formatters.timeAgo(DateTime.now()), 'Just now');
    });

    test('returns minutes ago', () {
      final d = DateTime.now().subtract(const Duration(minutes: 5));
      expect(Formatters.timeAgo(d), '5m ago');
    });

    test('returns hours ago', () {
      final d = DateTime.now().subtract(const Duration(hours: 3));
      expect(Formatters.timeAgo(d), '3h ago');
    });

    test('returns days ago', () {
      final d = DateTime.now().subtract(const Duration(days: 2));
      expect(Formatters.timeAgo(d), '2d ago');
    });

    test('falls back to date for >= 7 days', () {
      final d = DateTime.now().subtract(const Duration(days: 10));
      expect(Formatters.timeAgo(d), isNotEmpty);
    });
  });

  group('Formatters.daysBetween', () {
    test('counts full calendar days ignoring time', () {
      final a = DateTime(2026, 9, 7, 23, 0);
      final b = DateTime(2026, 9, 10, 1, 0);
      expect(Formatters.daysBetween(a, b), 3);
    });

    test('returns 0 for same day', () {
      expect(
        Formatters.daysBetween(DateTime(2026, 9, 7), DateTime(2026, 9, 7)),
        0,
      );
    });

    test('returns negative when end is before start', () {
      expect(
        Formatters.daysBetween(DateTime(2026, 9, 10), DateTime(2026, 9, 7)),
        -3,
      );
    });
  });
}
