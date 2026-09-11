import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

class CancelRentalUseCase {
  const CancelRentalUseCase(this._rentalRepository, this._inventoryRepository);

  final RentalRepository _rentalRepository;
  final InventoryRepository _inventoryRepository;

  Future<void> execute(Rental rental) async {
    // Only pending or non-overdue active rentals can be cancelled. This
    // mirrors the UI gate and blocks cancelling completed/declined rentals
    // or overdue ones (which must go through return + deposit penalty).
    if (!rental.isPending && !(rental.isActive && !rental.isOverdue)) {
      throw const FormatException('This rental can no longer be cancelled.');
    }
    try {
      await _rentalRepository.cancelRental(rental.id);
      await _inventoryRepository.updateStatus(rental.itemId, 'available');
    } catch (e) {
      throw NetworkFailure('Could not cancel this rental. Please try again.');
    }
  }
}


