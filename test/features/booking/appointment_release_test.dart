import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/admin/appointments/presentation/viewmodels/appointments_viewmodel.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/viewmodels/my_appointments_viewmodel.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = AppUser(
  uid: 'u1',
  fullName: 'Maria',
  email: 'm@m.com',
  phone: '0917',
  role: UserRole.customer,
);

Appointment _appt() => Appointment(
      id: 'a1',
      userId: 'u1',
      userName: 'Maria',
      itemId: 'i1',
      itemName: 'Gown',
      purpose: 'Fitting',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      status: Appointment.statusPending,
      createdAt: DateTime.now(),
    );

CatalogItem _scheduledGown() => CatalogItem(
      id: 'i1',
      name: 'Gown',
      category: 'dress',
      basePrice: 1800,
      securityDeposit: 1000,
      status: 'scheduled_for_appointment',
      createdAt: DateTime(2026, 1, 1),
    );

class _ReleaseAppointmentRepository implements AppointmentRepository {
  _ReleaseAppointmentRepository(this.appointments);

  final List<Appointment> appointments;

  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) =>
      Stream.value(appointments);

  @override
  Stream<List<Appointment>> allAppointmentsStream() =>
      Stream.value(appointments);

  @override
  Stream<List<Appointment>> pagedAppointmentsStream({int limit = 20}) =>
      Stream.value(appointments);

  @override
  Future<List<String>> bookedSlotsFor(DateTime day) async => [];

  @override
  Future<void> createAppointment(Appointment appointment) async {}

  @override
  Future<void> cancelAppointment(String id) async {
    final i = appointments.indexWhere((a) => a.id == id);
    if (i != -1) {
      appointments[i] = Appointment(
        id: appointments[i].id,
        userId: appointments[i].userId,
        userName: appointments[i].userName,
        itemId: appointments[i].itemId,
        itemName: appointments[i].itemName,
        purpose: appointments[i].purpose,
        scheduledAt: appointments[i].scheduledAt,
        status: Appointment.statusCancelled,
        createdAt: appointments[i].createdAt,
      );
    }
  }

  @override
  Future<void> updateStatus(String id, String status,
      {String? declineReason}) async {
    final i = appointments.indexWhere((a) => a.id == id);
    if (i != -1) {
      appointments[i] = Appointment(
        id: appointments[i].id,
        userId: appointments[i].userId,
        userName: appointments[i].userName,
        itemId: appointments[i].itemId,
        itemName: appointments[i].itemName,
        purpose: appointments[i].purpose,
        scheduledAt: appointments[i].scheduledAt,
        status: status,
        createdAt: appointments[i].createdAt,
      );
    }
  }
}

class _ReleaseInventoryRepository implements InventoryRepository {
  _ReleaseInventoryRepository(this.items);

  final List<CatalogItem> items;
  final List<(String, String)> statusChanges = [];

  @override
  Stream<List<CatalogItem>> itemsStream() =>
      Stream.value(List.unmodifiable(items));

  @override
  Future<String> addItem(CatalogItem item) async => 'x';

  @override
  Future<void> updateItem(CatalogItem item) async {}

  @override
  Future<void> updateStatus(String itemId, String status) async {
    statusChanges.add((itemId, status));
    final i = items.indexWhere((e) => e.id == itemId);
    if (i != -1) items[i] = items[i].copyWith(status: status);
  }

  @override
  Future<void> saveItemPhotos(String itemId, List<String> photos) async {}

  @override
  Future<List<String>> itemPhotos(String itemId) async => [];
}

class _ReleaseAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_user);

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
  Stream<int> usersCountStream() => Stream<int>.empty();

  @override
  Stream<List<AppUser>> watchUsers() => Stream<List<AppUser>>.value([]);
}

void main() {
  test('admin decline frees a scheduled item', () async {
    final inventory = _ReleaseInventoryRepository([_scheduledGown()]);
    final vm = AppointmentsViewModel(
      _ReleaseAppointmentRepository([_appt()]),
      inventory,
    );
    addTearDown(vm.dispose);

    final ok = await vm.decline(_appt(), 'No staff that day');

    expect(ok, isTrue);
    expect(
      inventory.statusChanges,
      contains(('i1', 'available')),
    );
  });

  test('customer cancel frees a scheduled item', () async {
    final inventory = _ReleaseInventoryRepository([_scheduledGown()]);
    final vm = MyAppointmentsViewModel(
      _ReleaseAppointmentRepository([_appt()]),
      _ReleaseAuthRepository(),
      inventory: inventory,
    );
    addTearDown(vm.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await vm.cancel(_appt());

    expect(ok, isTrue);
    expect(
      inventory.statusChanges,
      contains(('i1', 'available')),
    );
  });
}
