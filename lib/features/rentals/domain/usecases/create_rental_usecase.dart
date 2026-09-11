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
    // No back-scheduling: rental cannot start in the past (date-only compare
    // so same-day future times still pass).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(
      rental.startDate.year,
      rental.startDate.month,
      rental.startDate.day,
    );
    if (startDay.isBefore(today)) {
      throw const FormatException('Start date cannot be in the past.');
    }
    // Fixed 5-day allowance (e.g. Sep 15 -> Sep 19): date-only difference 4.
    final endDay = DateTime(
      rental.endDate.year,
      rental.endDate.month,
      rental.endDate.day,
    );
    if (endDay.difference(startDay).inDays != 4) {
      throw const FormatException('Rental period is fixed to 5 days.');
    }
    await _rentalRepository.createRental(rental);
    await _inventoryRepository.updateStatus(rental.itemId, 'rented');
  }
}

