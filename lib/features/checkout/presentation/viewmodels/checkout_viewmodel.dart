import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/create_rental_usecase.dart';

class CheckoutViewModel extends ChangeNotifier {
  CheckoutViewModel(this._createRental, this.item)
      : startDate = DateTime.now().add(const Duration(days: 2)),
        endDate = DateTime.now().add(const Duration(days: 5));

  final CreateRentalUseCase _createRental;
  final CatalogItem item;

  DateTime startDate;
  DateTime endDate;

  bool _confirming = false;
  String? _error;

  bool get isConfirming => _confirming;
  String? get error => _error;

  int get rentalDays => endDate.difference(startDate).inDays < 1
      ? 1
      : endDate.difference(startDate).inDays;

  double get rentalFee => item.basePrice * rentalDays;
  double get securityDeposit => item.securityDeposit;
  double get total => rentalFee + securityDeposit;

  void updateStartDate(DateTime date) {
    startDate = date;
    if (!endDate.isAfter(startDate)) {
      endDate = startDate.add(const Duration(days: 3));
    }
    notifyListeners();
  }

  void updateEndDate(DateTime date) {
    if (!date.isAfter(startDate)) return;
    endDate = date;
    notifyListeners();
  }

  Future<bool> confirm(AppUser user, {required String address}) async {
    _error = null;
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
      _error = 'Payment could not be completed. Please try again.';
      return false;
    } finally {
      _confirming = false;
      notifyListeners();
    }
  }
}
