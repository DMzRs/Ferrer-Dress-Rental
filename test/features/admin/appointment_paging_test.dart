import 'package:ferrer_rental_shop/features/admin/appointments/presentation/viewmodels/appointments_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Appointment _appt(String id) => Appointment(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      purpose: 'Trying On',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      status: Appointment.statusPending,
      createdAt: DateTime(2026, 8, 1),
    );

class _FakeAppointmentRepository implements AppointmentRepository {
  final List<Appointment> all =
      List.generate(25, (i) => _appt('a$i'));

  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) =>
      Stream<List<Appointment>>.empty();

  @override
  Stream<List<Appointment>> allAppointmentsStream() => Stream.value(all);

  @override
  Stream<List<Appointment>> pagedAppointmentsStream({int limit = 20}) =>
      Stream.value(all.take(limit).toList());

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

class _FakeInventoryRepository implements InventoryRepository {
  @override
  Stream<List<CatalogItem>> itemsStream() =>
      Stream<List<CatalogItem>>.empty();

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

void main() {
  test('starts paged at 20 with more available', () async {
    final vm = AppointmentsViewModel(
        _FakeAppointmentRepository(), _FakeInventoryRepository());
    await Future<void>.delayed(Duration.zero);
    expect(vm.pageSize, 20);
    expect(vm.requests.length, 20);
    expect(vm.hasMore, isTrue);
    vm.dispose();
  });

  test('loadMore grows the page', () async {
    final vm = AppointmentsViewModel(
        _FakeAppointmentRepository(), _FakeInventoryRepository());
    await Future<void>.delayed(Duration.zero);
    vm.loadMore();
    await Future<void>.delayed(Duration.zero);
    expect(vm.pageSize, 40);
    expect(vm.requests.length, 25);
    expect(vm.hasMore, isFalse);
    vm.dispose();
  });
}
