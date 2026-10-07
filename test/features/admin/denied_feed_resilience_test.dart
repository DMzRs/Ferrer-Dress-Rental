import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/admin/appointments/presentation/viewmodels/appointments_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/inventory/presentation/viewmodels/inventory_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/rental_management/presentation/viewmodels/rental_management_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/reports/presentation/viewmodels/reports_viewmodel.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Denied Firestore reads arrive as asynchronous stream errors (exactly
/// what permission-denied looks like at runtime).
Stream<T> _denied<T>() async* {
  await Future<void>.delayed(Duration.zero);
  throw Exception('permission-denied');
}

class _DeniedRentalRepository implements RentalRepository {
  @override
  Stream<List<Rental>> userRentalsStream(String userId) => _denied();

  @override
  Stream<List<Rental>> allRentalsStream() => _denied();

  @override
  Stream<List<Rental>> pagedRentalsStream({int limit = 20}) => _denied();

  @override
  Future<String> createRental(Rental rental) async => 'new-id';

  @override
  Future<void> completeRental(String id, {DateTime? returnedAt}) async {}

  @override
  Future<void> cancelRental(String id) async {}

  @override
  Future<void> updateRentalStatus(String id, String status,
          {String? declineReason}) async {}
}

class _DeniedInventoryRepository implements InventoryRepository {
  @override
  Stream<List<CatalogItem>> itemsStream() => _denied();

  @override
  Future<String> addItem(CatalogItem item) async => 'x';

  @override
  Future<void> updateItem(CatalogItem item) async {}

  @override
  Future<void> updateStatus(String itemId, String status) async {}

  @override
  Future<void> saveItemPhotos(String itemId, List<String> photos) async {}

  @override
  Future<List<String>> itemPhotos(String itemId) async => [];
}

class _DeniedAppointmentRepository implements AppointmentRepository {
  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) =>
      _denied();

  @override
  Stream<List<Appointment>> allAppointmentsStream() => _denied();

  @override
  Stream<List<Appointment>> pagedAppointmentsStream({int limit = 20}) =>
      _denied();

  @override
  Future<List<String>> bookedSlotsFor(DateTime day) async => [];

  @override
  Future<void> createAppointment(Appointment appointment) async {}

  @override
  Future<void> cancelAppointment(String id) async {}

  @override
  Future<void> updateStatus(String id, String status,
          {String? declineReason}) async {}
}

class _DeniedAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(null);

  @override
  Future<Result<AppUser>> signIn(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signUp(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendSignInLink(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signInWithEmailLink(
          {required String email,
          required String link,
          String? fullName,
          String? phone,
          String? password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<Result<AppUser>> linkGoogleAccount(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> createAdmin(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> updateUserRole(
          {required String uid, required UserRole role}) =>
      throw UnimplementedError();

  @override
  Stream<String> emailLinkStream() => Stream<String>.empty();

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<void>> updateProfile(
          {String? fullName,
          String? phone,
          String? address,
          List<String>? savedPlaces}) =>
      throw UnimplementedError();

  @override
  Stream<int> usersCountStream() => _denied();

  @override
  Stream<List<AppUser>> watchUsers() => _denied();
}

void main() {
  test('denied feeds settle loading instead of hanging', () async {
    final rentals = _DeniedRentalRepository();
    final inventory = _DeniedInventoryRepository();
    final appointments = _DeniedAppointmentRepository();
    final auth = _DeniedAuthRepository();

    final dashboard = DashboardViewModel(
      rentalRepository: rentals,
      inventoryRepository: inventory,
      appointmentRepository: appointments,
      authRepository: auth,
    );
    final reports = ReportsViewModel(rentals);
    final appts = AppointmentsViewModel(appointments, inventory);
    final rentalMgmt = RentalManagementViewModel(
      rentals,
      ProcessReturnUseCase(rentals, inventory),
      ConfirmRentalUseCase(rentals),
      DeclineRentalUseCase(rentals, inventory),
    );
    final stock = InventoryViewModel(inventory);
    addTearDown(() {
      dashboard.dispose();
      reports.dispose();
      appts.dispose();
      rentalMgmt.dispose();
      stock.dispose();
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(dashboard.metrics.isLoading, isFalse);
    expect(reports.isLoading, isFalse);
    expect(appts.isLoading, isFalse);
    expect(rentalMgmt.isLoading, isFalse);
    expect(stock.isLoading, isFalse);
  });
}
