import 'package:intl/intl.dart';

/// Date, money, and range formatting helpers.
class Formatters {
  Formatters._();

  /// Peso formatting with thousands separators.
  static String peso(num amount) {
    final value = amount.toDouble();
    return '₱${NumberFormat('#,##0.##').format(value)}';
  }

  /// Full date like `Jan 5, 2026`.
  static String date(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  /// Short date without year.
  static String shortDate(DateTime d) => DateFormat('MMM d').format(d);

  /// Weekday plus month and day.
  static String monthDay(DateTime d) => DateFormat('EEE, MMM d').format(d);

  /// Rental period label spanning two dates.
  static String range(DateTime start, DateTime end) =>
      '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';

  /// Full month and year label.
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

  /// Relative time like `5m ago`.
  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(d);
  }

  /// Whole calendar days between two dates.
  static int daysBetween(DateTime start, DateTime end) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    return b.difference(a).inDays;
  }
}
