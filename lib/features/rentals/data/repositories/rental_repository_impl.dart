import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/data/datasources/firebase_rental_data_source.dart';
import 'package:ferrer_rental_shop/features/rentals/data/datasources/mock_rental_data_source.dart';
import 'package:ferrer_rental_shop/features/rentals/data/datasources/rental_data_source.dart';

class RentalRepositoryImpl implements RentalRepository {
  const RentalRepositoryImpl(this._dataSource);

  final RentalDataSource _dataSource;

  static RentalDataSource defaultDataSource() {
    if (AppConfig.firebaseEnabled) return FirebaseRentalDataSource();
    return MockRentalDataSource();
  }

  @override
  Stream<List<Rental>> userRentalsStream(String userId) =>
      _dataSource.userRentalsStream(userId);

  @override
  Stream<List<Rental>> allRentalsStream() => _dataSource.allRentalsStream();

  @override
  Future<void> createRental(Rental rental) => _dataSource.createRental(rental);

  @override
  Future<void> completeRental(String rentalId, {DateTime? returnedAt}) =>
      _dataSource.completeRental(rentalId, returnedAt: returnedAt);

  @override
  Future<void> cancelRental(String rentalId) => _dataSource.cancelRental(rentalId);

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

