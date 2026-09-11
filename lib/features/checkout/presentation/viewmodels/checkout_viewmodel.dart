import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/create_rental_usecase.dart';

class CheckoutViewModel extends ChangeNotifier {
  /// Fixed rental allowance: 5 inclusive days (e.g. Sep 15 -> Sep 19).
  /// Date-only difference is [dateDifferenceDays] (4); totalDays inclusive is 5.
  static const int fixedRentalDays = 5;
  static const int dateDifferenceDays = fixedRentalDays - 1;

  CheckoutViewModel(this._createRental, this.item)
      : startDate = DateTime.now().add(const Duration(days: 2)),
        endDate = DateTime.now().add(
          Duration(days: 2 + dateDifferenceDays),
        );

  final CreateRentalUseCase _createRental;
  final CatalogItem item;

  DateTime startDate;
  DateTime endDate;

  bool _confirming = false;
  String? _error;

  bool get isConfirming => _confirming;
  String? get error => _error;

  int get rentalDays => fixedRentalDays;

  double get rentalFee => item.basePrice * rentalDays;
  double get securityDeposit => item.securityDeposit;
  double get total => rentalFee + securityDeposit;

  void updateStartDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day.isBefore(today)) {
      _error = 'Start date cannot be in the past.';
      notifyListeners();
      return;
    }
    _error = null;
    // Fixed 5-day allowance: return date always follows the start date.
    startDate = DateTime(date.year, date.month, date.day);
    endDate = startDate.add(const Duration(days: dateDifferenceDays));
    notifyListeners();
  }

  void updateEndDate(DateTime date) {
    // Rental period is fixed to 5 days; end date is derived from start date.
    _error = 'Rental period is fixed to 5 days.';
    notifyListeners();
  }

  Future<bool> confirm(AppUser user, {required String address}) async {
    _error = null;
    // No back-scheduling: block past start dates before hitting Firestore so
    // the user gets "Start date cannot be in the past" instead of a payment error.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    if (startDay.isBefore(today)) {
      _error = 'Start date cannot be in the past.';
      notifyListeners();
      return false;
    }
    if (!endDate.isAfter(startDate)) {
      _error = 'Return date must be after the start date.';
      notifyListeners();
      return false;
    }
    // Fixed 5-day allowance (date-only difference must equal 4).
    final startDayOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endDayOnly = DateTime(endDate.year, endDate.month, endDate.day);
    if (endDayOnly.difference(startDayOnly).inDays != dateDifferenceDays) {
      _error = 'Rental period is fixed to 5 days.';
      notifyListeners();
      return false;
    }
    _confirming = true;
    notifyListeners();

    final rental = Rental(
      id: '',
      userId: user.uid,
      userName: user.fullName,
      itemId: item.id,
      itemName: item.name,
      itemCategory: item.category,
      startDate: startDate,
      endDate: endDate,
      rentalFee: rentalFee,
      securityDeposit: securityDeposit,
      total: total,
      status: 'pending',
      deliveryAddress: address.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await _createRental.execute(rental);
      return true;
    } catch (e) {
      // Surface the underlying cause (e.g. permission-denied, not-found,
      // network) so the UI/snackbar and logs show WHY it failed instead of
      // a generic message. Keep the friendly prefix for users.
      _error = 'Payment could not be completed. Details: $e';
      return false;
    } finally {
      _confirming = false;
      notifyListeners();
    }
  }
}
