import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/cancel_rental_usecase.dart';

class RentalDetailsViewModel extends ChangeNotifier {
  RentalDetailsViewModel(this._cancelRental);

  final CancelRentalUseCase _cancelRental;

  bool _busy = false;
  String? _error;

  bool get busy => _busy;
  String? get error => _error;

  Future<bool> cancel(Rental rental) async {
    _busy = true;
    notifyListeners();
    try {
      await _cancelRental.execute(rental);
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

