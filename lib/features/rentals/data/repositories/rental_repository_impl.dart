import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/data/datasources/firebase_rental_data_source.dart';
import 'package:ferrer_rental_shop/features/rentals/data/datasources/mock_rental_data_source.dart';
import 'package:ferrer_rental_shop/features/rentals/data/datasources/rental_data_source.dart';

/// Delegates rental operations to the configured data source.
class RentalRepositoryImpl implements RentalRepository {
  const RentalRepositoryImpl(this._dataSource);

  final RentalDataSource _dataSource;

  /// Picks the Firebase or mock rental source from app config.
  static RentalDataSource defaultDataSource() {
    if (AppConfig.firebaseEnabled) return FirebaseRentalDataSource();
    return MockRentalDataSource();
  }

  /// Streams rentals for one user, newest first.
  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      _dataSource.userRentalsStream(userId);

  /// Streams every rental, newest first, for admin views.
  @override
  Stream<List<Rental>> allRentalsStream() => _dataSource.allRentalsStream();

  /// Streams the newest rentals up to the given limit.
  @override
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) =>
      _dataSource.pagedRentalsStream(limit: limit);

  /// Creates a rental and returns its new id.
  @override
  Future<String> createRental(Rental rental) =>
      _dataSource.createRental(rental);

  /// Marks a rental completed with its return timestamp.
  @override
  Future<void> completeRental(String rentalId, {DateTime? returnedAt}) =>
      _dataSource.completeRental(rentalId, returnedAt: returnedAt);

  /// Marks a rental cancelled.
  @override
  Future<void> cancelRental(String rentalId) => _dataSource.cancelRental(rentalId);

  /// Updates status and optional decline reason.
  @override
  Future<void> updateRentalStatus(
    String rentalId,
    String status, {
    String? declineReason,
  }) =>
      _dataSource.updateRentalStatus(
        rentalId,
        status,
        declineReason: declineReason,
      );
}

