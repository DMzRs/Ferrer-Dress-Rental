import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

/// Admin decision that rejects a pending rental request; the item goes back
/// to the available catalog.
class DeclineRentalUseCase {
  const DeclineRentalUseCase(this._rentalRepository, this._inventoryRepository);

  final RentalRepository _rentalRepository;
  final InventoryRepository _inventoryRepository;

  Future<void> execute(Rental rental, {String? reason}) async {
    if (!rental.isPending) {
      throw const FormatException('Only pending rentals can be declined.');
    }
    final trimmed = reason?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw const FormatException('Please write the reason for declining.');
    }
    try {
      await _rentalRepository.updateRentalStatus(
        rental.id,
        'declined',
        declineReason: trimmed,
      );
      await _inventoryRepository.updateStatus(rental.itemId, 'available');
    } catch (e) {
      throw NetworkFailure('Could not decline this rental. Please try again.');
    }
  }
}
