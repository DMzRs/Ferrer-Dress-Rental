import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

/// Admin decision that turns a customer's pending rental request into a
/// confirmed (active) rental.
class ConfirmRentalUseCase {
  const ConfirmRentalUseCase(this._rentalRepository);

  final RentalRepository _rentalRepository;

  Future<void> execute(Rental rental) async {
    if (!rental.isPending) {
      throw const FormatException('Only pending rentals can be confirmed.');
    }
    try {
      await _rentalRepository.updateRentalStatus(rental.id, 'active');
    } catch (e) {
      throw NetworkFailure('Could not confirm this rental. Please try again.');
    }
  }
}
