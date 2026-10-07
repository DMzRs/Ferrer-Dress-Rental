import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/audit/domain/audit_logger.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/cancel_rental_usecase.dart';

/// Holds cancel state for the rental details screen.
class RentalDetailsViewModel extends ChangeNotifier {
  RentalDetailsViewModel(this._cancelRental, {this._audit});

  final CancelRentalUseCase _cancelRental;
  final AuditLogger? _audit;

  bool _busy = false;
  String? _error;

  /// True while a cancel request is in flight.
  bool get busy => _busy;
  /// Latest cancel failure message, if any.
  String? get error => _error;

  /// Cancels the rental and logs the action, reporting success.
  Future<bool> cancel(Rental rental) async {
    _busy = true;
    notifyListeners();
    try {
      await _cancelRental.execute(rental);
      await _audit?.log('rental.cancelled',
          targetType: 'rental', targetId: rental.id);
      return true;
    } on Failure catch (failure) {
      _error = failure.message;
      return false;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}

