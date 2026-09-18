import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

class MyRentalsViewModel extends ChangeNotifier {
  MyRentalsViewModel(this._rentalRepository, this._authRepository) {
    _authSub = _authRepository.authStateChanges.listen((user) {
      _userId = user?.uid;
      _rentalSub?.cancel();
      if (_userId != null) {
        _rentalSub =
            _rentalRepository.userRentalsStream(_userId!).listen(_onRentals);
      }
    });
  }

  final RentalRepository _rentalRepository;
  final AuthRepository _authRepository;

  StreamSubscription? _authSub;
  StreamSubscription<List<Rental>>? _rentalSub;
  String? _userId;

  List<Rental> _rentals = const [];
  bool _loading = true;
  String _filter = 'all';

  List<Rental> get rentals => _filtered;
  bool get isLoading => _loading;
  String get filter => _filter;

  /// Unfiltered list for the notifications feed.
  List<Rental> get allRentalsForNotifications =>
      List.unmodifiable(_rentals);

  int get pendingCount => _rentals.where((r) => r.isPending).length;

  int get activeCount =>
      _rentals.where((r) => r.isActive || r.isOverdue).length;

  /// Warning signals computed over ALL rentals so the banner reads the same
  /// under every filter.
  bool get hasOverdue => _rentals.any((r) => r.isOverdue);

  bool get hasDueSoon => _rentals.any((r) => r.isDueSoon);

  int get dueSoonCount => _rentals.where((r) => r.isDueSoon).length;

  String? get firstOverdueId {
    final ids = overdueIds;
    return ids.isEmpty ? null : ids.first;
  }

  List<String> get overdueIds {
    final ids = <String>[];
    for (final rental in _rentals) {
      if (rental.isOverdue) ids.add(rental.id);
    }
    return ids;
  }

  int get overdueCount => overdueIds.length;

  List<Rental> get _filtered {
    switch (_filter) {
      case 'pending':
        return _rentals.where((r) => r.isPending).toList();
      case 'active':
        return _rentals.where((r) => r.status == 'active').toList();
      case 'completed':
        return _rentals.where((r) => r.isCompleted).toList();
      default:
        return _rentals;
    }
  }

  void _onRentals(List<Rental> rentals) {
    _rentals = rentals..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _loading = false;
    notifyListeners();
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _rentalSub?.cancel();
    super.dispose();
  }
}


