import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

class MonthlyReportPoint {
  final String label;
  final double revenue;
  final int rentalsCompleted;

  const MonthlyReportPoint({
    required this.label,
    required this.revenue,
    required this.rentalsCompleted,
  });
}

class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel(this._repository) {
    _subscription = _repository.allRentalsStream().listen(_onRentals);
  }

  final RentalRepository _repository;
  StreamSubscription<List<Rental>>? _subscription;

  List<MonthlyReportPoint> _points = const [];
  double _totalRevenue = 0;
  double _heldDeposits = 0;
  int _completedCount = 0;
  bool _loading = true;

  List<MonthlyReportPoint> get points => _points;
  double get totalRevenue => _totalRevenue;
  double get heldDeposits => _heldDeposits;
  int get completedCount => _completedCount;
  bool get isLoading => _loading;
  int get activeCount => _activeCount;

  int _activeCount = 0;

  void _onRentals(List<Rental> rentals) {
    final now = DateTime.now();
    final valid = rentals.where((r) => r.status != 'cancelled').toList();

    _totalRevenue = valid.fold(0, (sum, r) => sum + r.rentalFee);
    _heldDeposits =
        valid.where((r) => r.status == 'active').fold(0, (sum, r) => sum + r.securityDeposit);
    _completedCount = rentals.where((r) => r.isCompleted).length;
    _activeCount = rentals.where((r) => r.status == 'active').length;

    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final buckets = <MonthlyReportPoint>[];
    for (var back = 5; back >= 0; back--) {
      final month = DateTime(now.year, now.month - back);
      final monthRentals = valid
          .where((r) =>
              DateTime(r.endDate.year, r.endDate.month)
                  .isAtSameMomentAs(DateTime(month.year, month.month)))
          .toList();
      buckets.add(MonthlyReportPoint(
        label: labels[month.month - 1],
        revenue: monthRentals.fold(0, (sum, r) => sum + r.rentalFee),
        rentalsCompleted:
            monthRentals.where((r) => r.isCompleted).length,
      ));
    }
    _points = buckets;
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}


