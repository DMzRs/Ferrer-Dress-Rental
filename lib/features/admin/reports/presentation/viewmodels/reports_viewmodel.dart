import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

enum ReportPeriod { daily, weekly, monthly }

class ReportPoint {
  final String label;
  final double revenue;
  final int rentalsCompleted;
  final double developerCut;

  const ReportPoint({
    required this.label,
    required this.revenue,
    required this.rentalsCompleted,
    required this.developerCut,
  });
}

class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel(this._repository) {
    _subscription = _repository.allRentalsStream().listen(_onRentals);
  }

  /// Developer's platform share of every rental fee.
  static const double developerRate = 0.05;

  final RentalRepository _repository;
  StreamSubscription<List<Rental>>? _subscription;

  ReportPeriod _period = ReportPeriod.monthly;
  List<ReportPoint> _points = const [];
  double _totalRevenue = 0;
  double _totalDeveloperCut = 0;
  double _heldDeposits = 0;
  int _completedCount = 0;
  bool _loading = true;

  ReportPeriod get period => _period;
  List<ReportPoint> get points => _points;
  double get totalRevenue => _totalRevenue;
  double get totalDeveloperCut => _totalDeveloperCut;
  double get heldDeposits => _heldDeposits;
  int get completedCount => _completedCount;
  bool get isLoading => _loading;
  int get activeCount => _activeCount;

  double get periodRevenue =>
      _points.fold(0, (sum, p) => sum + p.revenue);
  double get periodDeveloperCut =>
      _points.fold(0, (sum, p) => sum + p.developerCut);
  int get periodCompleted =>
      _points.fold(0, (sum, p) => sum + p.rentalsCompleted);

  int _activeCount = 0;
  List<Rental> _cache = const [];

  void setPeriod(ReportPeriod value) {
    if (value == _period) return;
    _period = value;
    _rebuild();
  }

  void _onRentals(List<Rental> rentals) {
    _cache = rentals;
    _rebuild();
  }

  void _rebuild() {
    final valid = _cache.where((r) => r.status != 'cancelled').toList();

    _totalRevenue = valid.fold(0, (sum, r) => sum + r.rentalFee);
    _totalDeveloperCut = _totalRevenue * developerRate;
    _heldDeposits =
        valid.where((r) => r.status == 'active').fold(0, (sum, r) => sum + r.securityDeposit);
    _completedCount = _cache.where((r) => r.isCompleted).length;
    _activeCount = _cache.where((r) => r.status == 'active').length;

    switch (_period) {
      case ReportPeriod.daily:
        _points = _daily(valid);
        break;
      case ReportPeriod.weekly:
        _points = _weekly(valid);
        break;
      case ReportPeriod.monthly:
        _points = _monthly(valid);
        break;
    }
    _loading = false;
    notifyListeners();
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  List<ReportPoint> _daily(List<Rental> valid) {
    final now = DateTime.now();
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final buckets = <ReportPoint>[];
    for (var back = 13; back >= 0; back--) {
      final day = _day(now.subtract(Duration(days: back)));
      final dayRentals =
          valid.where((r) => _day(r.endDate) == day).toList();
      final revenue = dayRentals.fold(0.0, (sum, r) => sum + r.rentalFee);
      buckets.add(ReportPoint(
        label: '${labels[day.month - 1]} ${day.day}',
        revenue: revenue,
        rentalsCompleted: dayRentals.where((r) => r.isCompleted).length,
        developerCut: revenue * developerRate,
      ));
    }
    return buckets;
  }

  List<ReportPoint> _weekly(List<Rental> valid) {
    final now = DateTime.now();
    final thisMonday = _day(now).subtract(Duration(days: now.weekday - 1));
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final buckets = <ReportPoint>[];
    for (var back = 7; back >= 0; back--) {
      final start = thisMonday.subtract(Duration(days: 7 * back));
      final end = start.add(const Duration(days: 7));
      final weekRentals = valid
          .where((r) =>
              !r.endDate.isBefore(start) && r.endDate.isBefore(end))
          .toList();
      final revenue = weekRentals.fold(0.0, (sum, r) => sum + r.rentalFee);
      buckets.add(ReportPoint(
        label: '${labels[start.month - 1]} ${start.day}',
        revenue: revenue,
        rentalsCompleted: weekRentals.where((r) => r.isCompleted).length,
        developerCut: revenue * developerRate,
      ));
    }
    return buckets;
  }

  List<ReportPoint> _monthly(List<Rental> valid) {
    final now = DateTime.now();
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final buckets = <ReportPoint>[];
    for (var back = 5; back >= 0; back--) {
      final month = DateTime(now.year, now.month - back);
      final monthRentals = valid
          .where((r) =>
              DateTime(r.endDate.year, r.endDate.month)
                  .isAtSameMomentAs(DateTime(month.year, month.month)))
          .toList();
      final revenue = monthRentals.fold(0.0, (sum, r) => sum + r.rentalFee);
      buckets.add(ReportPoint(
        label: labels[month.month - 1],
        revenue: revenue,
        rentalsCompleted:
            monthRentals.where((r) => r.isCompleted).length,
        developerCut: revenue * developerRate,
      ));
    }
    return buckets;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
