import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String peso(num amount) {
    final value = amount.toDouble();
    return '₱${NumberFormat('#,##0.##').format(value)}';
  }

  static String date(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  static String shortDate(DateTime d) => DateFormat('MMM d').format(d);

  static String monthDay(DateTime d) => DateFormat('EEE, MMM d').format(d);

  static String range(DateTime start, DateTime end) =>
      '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';

  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(d);
  }

  static int daysBetween(DateTime start, DateTime end) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    return b.difference(a).inDays;
  }
}
