import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class MonthCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;
  final int maxDaysAhead;

  const MonthCalendar({
    super.key,
    required this.selectedDate,
    required this.onSelect,
    this.maxDaysAhead = 90,
  });

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _visibleMonth;
  late final DateTime _today;
  late final DateTime _maxDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _maxDate = _today.add(Duration(days: widget.maxDaysAhead));
    _visibleMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _shiftMonth(int months) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + months);
    });
  }

  bool get _canGoBack =>
      !_visibleMonth.isBefore(DateTime(_today.year, _today.month));

  bool get _canGoForward => !_visibleMonth.isAfter(
      DateTime(_maxDate.year, _maxDate.month));

  static const List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final leadingBlanks = (firstDayOfMonth.weekday - 1) % 7;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.goldSoft.withValues(alpha: .8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blush.withValues(alpha: .22),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _canGoBack ? () => _shiftMonth(-1) : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 26),
                color: AppColors.roseDark,
                disabledColor: AppColors.champagne,
              ),
              Expanded(
                child: Text(
                  '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: _canGoForward ? () => _shiftMonth(1) : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 26),
                color: AppColors.roseDark,
                disabledColor: AppColors.champagne,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final day in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft.withValues(alpha: .7),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildWeeks(leadingBlanks, daysInMonth),
        ],
      ),
    );
  }

  List<Widget> _buildWeeks(int leadingBlanks, int daysInMonth) {
    final cells = <Widget?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var d = 1; d <= daysInMonth; d++) _buildCell(d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final weeks = <Widget>[];
    for (var w = 0; w < cells.length / 7; w++) {
      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: cells[w * 7 + c] ?? const SizedBox(height: 38)),
            ],
          ),
        ),
      );
    }
    return weeks;
  }

  Widget? _buildCell(int day) {
    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final isPast = date.isBefore(_today);
    final beyondMax = date.isAfter(_maxDate);
    final disabled = isPast || beyondMax;
    final isSelected = _sameDay(date, widget.selectedDate);

    return GestureDetector(
      onTap: disabled ? null : () => widget.onSelect(date),
      child: Container(
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.brandGradient : null,
          color: isSelected ? null : Colors.transparent,
          shape: BoxShape.circle,
          border: _sameDay(date, _today) && !isSelected
              ? Border.all(color: AppColors.blush, width: 1.4)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.rose.withValues(alpha: .35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: disabled
                ? AppColors.champagne
                : isSelected
                    ? Colors.white
                    : AppColors.ink,
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}
