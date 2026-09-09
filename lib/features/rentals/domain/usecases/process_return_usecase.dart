import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

class ProcessReturnResult {
  final String itemName;
  final double depositRefunded;
  final bool wasOverdue;

  const ProcessReturnResult({
    required this.itemName,
    required this.depositRefunded,
    required this.wasOverdue,
  });
}

class ProcessReturnUseCase {
  const ProcessReturnUseCase(this._rentalRepository, this._inventoryRepository);

  final RentalRepository _rentalRepository;
  final InventoryRepository _inventoryRepository;

  Future<ProcessReturnResult> execute(Rental rental) async {
    final wasOverdue = rental.isOverdue;
    await _rentalRepository.completeRental(rental.id, returnedAt: DateTime.now());
    await _inventoryRepository.updateStatus(rental.itemId, 'available');
    return ProcessReturnResult(
      itemName: rental.itemName,
      depositRefunded:
          wasOverdue ? rental.securityDeposit * .5 : rental.securityDeposit,
      wasOverdue: wasOverdue,
    );
  }
}

