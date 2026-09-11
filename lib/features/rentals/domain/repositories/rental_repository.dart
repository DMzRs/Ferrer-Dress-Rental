import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';

abstract class RentalRepository {
  Stream<List<Rental>> userRentalsStream(String userId);

  Stream<List<Rental>> allRentalsStream();

  Future<void> createRental(Rental rental);

  Future<void> completeRental(String rentalId, {DateTime? returnedAt});

  Future<void> cancelRental(String rentalId);

  Future<void> updateRentalStatus(
    String rentalId,
    String status, {
    String? declineReason,
  });
}

