import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';

abstract class RentalRepository {
  Stream<List<Rental>> userRentalsStream(String userId);

  Stream<List<Rental>> allRentalsStream();

  /// Paged admin feed, newest first. Defaults to the full stream; remote
  /// sources override with a server-side limit.
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) =>
      allRentalsStream();

  /// Creates the rental and returns its new id.
  Future<String> createRental(Rental rental);

  Future<void> completeRental(String rentalId, {DateTime? returnedAt});

  Future<void> cancelRental(String rentalId);

  Future<void> updateRentalStatus(
    String rentalId,
    String status, {
    String? declineReason,
  });
}

