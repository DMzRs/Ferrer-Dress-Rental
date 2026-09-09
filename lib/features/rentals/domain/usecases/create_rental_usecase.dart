import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

class CreateRentalUseCase {
  const CreateRentalUseCase(this._rentalRepository, this._inventoryRepository);

  final RentalRepository _rentalRepository;
  final InventoryRepository _inventoryRepository;

  Future<void> execute(Rental rental) async {
    if (!rental.endDate.isAfter(rental.startDate)) {
      throw const FormatException('Return date must be after the start date.');
    }
    await _rentalRepository.createRental(rental);
    await _inventoryRepository.updateStatus(rental.itemId, 'rented');
  }
}

