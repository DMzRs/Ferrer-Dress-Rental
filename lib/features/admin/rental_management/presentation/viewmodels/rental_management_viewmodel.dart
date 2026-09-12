import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';

enum RentalTab { requests, rejected, active, overdue, completed }

class RentalManagementViewModel extends ChangeNotifier {
  RentalManagementViewModel(
    this._repository,
    this._processReturn,
    this._confirmRental,
    this._declineRental,
  ) {
    _subscription = _repository.allRentalsStream().listen(_onRentals);
  }

  final RentalRepository _repository;
  final ProcessReturnUseCase _processReturn;
  final ConfirmRentalUseCase _confirmRental;
  final DeclineRentalUseCase _declineRental;

  StreamSubscription<List<Rental>>? _subscription;

  List<Rental> _rentals = [];
  bool _loading = true;
  bool _processingId = false;
  String? _processingRentalId;

  List<Rental> get rentals => _filtered;
  List<Rental> get allRentals => _rentals;
  bool get isLoading => _loading;
  bool get isProcessing => _processingId;
  String? get processingRentalId => _processingRentalId;

  int get pendingCount => _rentals.where((r) => r.isPending).length;
  int get activeCount =>
      _rentals.where((r) => r.status == 'active' && !r.isOverdue).length;
  int get overdueCount => _rentals.where((r) => r.isOverdue).length;
  int get completedCount => _rentals.where((r) => r.isCompleted).length;
  int get rejectedCount =>
      _rentals.where((r) => r.isDeclined || r.isCancelled).length;

  List<Rental> get _filtered {
    switch (_tab) {
      case RentalTab.requests:
        return _rentals.where((r) => r.isPending).toList();
      case RentalTab.overdue:
        return _rentals.where((r) => r.isOverdue).toList();
      case RentalTab.completed:
        return _rentals.where((r) => r.isCompleted).toList();
      case RentalTab.rejected:
        return _rentals
            .where((r) => r.isDeclined || r.isCancelled)
            .toList();
      case RentalTab.active:
        return _rentals.where((r) => r.status == 'active').toList();
    }
  }

  RentalTab _tab = RentalTab.active;
  RentalTab get tab => _tab;

  /// Record id to spotlight (from a dashboard deep-link). Cleared whenever
  /// the tab changes.
  String? _highlightId;
  String? get highlightId => _highlightId;

  void setTab(RentalTab tab) {
    _tab = tab;
    _highlightId = null;
    notifyListeners();
  }

  void highlight(String rentalId) {
    _highlightId = rentalId;
    notifyListeners();
  }

  void _onRentals(List<Rental> rentals) {
    _rentals = rentals..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _loading = false;
    notifyListeners();
  }

  Future<ProcessReturnResult?> processReturn(Rental rental) async {
    _processingRentalId = rental.id;
    _processingId = true;
    notifyListeners();
    try {
      return await _processReturn.execute(rental);
    } catch (_) {
      return null;
    } finally {
      _processingId = false;
      _processingRentalId = null;
      notifyListeners();
    }
  }

  /// Returns null on success, otherwise an error message.
  Future<String?> confirmRental(Rental rental) async {
    _processingRentalId = rental.id;
    _processingId = true;
    notifyListeners();
    try {
      await _confirmRental.execute(rental);
      return null;
    } catch (_) {
      return 'Could not confirm this rental. Please try again.';
    } finally {
      _processingId = false;
      _processingRentalId = null;
      notifyListeners();
    }
  }

  /// Returns null on success, otherwise an error message.
  Future<String?> declineRental(Rental rental, String reason) async {
    if (reason.trim().isEmpty) {
      return 'Please write the reason for declining.';
    }
    _processingRentalId = rental.id;
    _processingId = true;
    notifyListeners();
    try {
      await _declineRental.execute(rental, reason: reason);
      return null;
    } catch (_) {
      return 'Could not decline this rental. Please try again.';
    } finally {
      _processingId = false;
      _processingRentalId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}


