import 'package:ferrer_rental_shop/features/booking/data/datasources/mock_appointment_data_source.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

Appointment _appt({
  required String id,
  required DateTime at,
  required String status,
  String? itemId,
}) =>
    Appointment(
      id: id,
      userId: 'u1',
      userName: 'Maria',
      itemId: itemId,
      itemName: itemId == null ? null : 'Gown',
      purpose: 'Fitting',
      scheduledAt: at,
      status: status,
      createdAt: DateTime(2026, 9, 1),
    );

class _ConflictAppointmentRepository implements AppointmentRepository {
  _ConflictAppointmentRepository({
    required this.appointments,
    required this.booked,
  });

  final List<Appointment> appointments;
  List<String> booked;
  Appointment? lastCreated;

  @override
  Future<List<String>> bookedSlotsFor(DateTime day) async => booked;

  @override
  Stream<List<Appointment>> pagedAppointmentsStream({int limit = 20}) =>
      Stream.value(appointments);

  @override
  Future<void> createAppointment(Appointment a) async {
    lastCreated = a;
  }

  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) =>
      Stream.value(
          appointments.where((a) => a.userId == userId).toList());

  @override
  Stream<List<Appointment>> allAppointmentsStream() =>
      Stream.value(appointments);

  @override
  Future<void> cancelAppointment(String id) async {}

  @override
  Future<void> updateStatus(String id, String status,
          {String? declineReason}) async {}
}

DateTime _day(int hour) {
  final base = DateTime.now().add(const Duration(days: 3));
  return DateTime(base.year, base.month, base.day, hour);
}

void main() {
  group('slot conflict guards', () {
    test('confirm re-checks slots and refuses a just-taken one', () async {
      final repo = _ConflictAppointmentRepository(
        appointments: const [],
        booked: const [],
      );
      final vm = BookingViewModel(repo);
      addTearDown(vm.dispose);
      await vm.init();
      vm.selectSlot('11:00 AM');
      // Someone else grabs the slot after the UI loaded.
      repo.booked = ['11:00 AM'];

      final ok = await vm.confirm(userId: 'u1', userName: 'Maria');

      expect(ok, isFalse);
      expect(vm.error, contains('just taken'));
      expect(repo.lastCreated, isNull);
    });

    test('refuses a duplicate live request for the same cloth and time',
        () async {
      final at = _day(11);
      final repo = _ConflictAppointmentRepository(
        appointments: [
          _appt(
              id: 'a1',
              at: at,
              status: Appointment.statusPending,
              itemId: 'i1'),
        ],
        booked: const [],
      );
      final vm = BookingViewModel(repo);
      addTearDown(vm.dispose);
      await vm.init();
      await vm.selectDate(DateTime(at.year, at.month, at.day));
      vm.selectSlot('11:00 AM');

      final ok = await vm.confirm(
        userId: 'u1',
        userName: 'Maria',
        itemId: 'i1',
        itemName: 'Gown',
      );

      expect(ok, isFalse);
      expect(vm.error, contains('already'));
      expect(repo.lastCreated, isNull);
    });

    test('refuses a second live request for the same cloth at another time',
        () async {
      final at = _day(11);
      final repo = _ConflictAppointmentRepository(
        appointments: [
          _appt(
              id: 'a1',
              at: at,
              status: Appointment.statusPending,
              itemId: 'i1'),
        ],
        booked: const [],
      );
      final vm = BookingViewModel(repo);
      addTearDown(vm.dispose);
      await vm.init();
      // A different day and slot than the live request.
      await vm.selectDate(DateTime(at.year, at.month, at.day + 1));
      vm.selectSlot('2:00 PM');

      final ok = await vm.confirm(
        userId: 'u1',
        userName: 'Maria',
        itemId: 'i1',
        itemName: 'Gown',
      );

      expect(ok, isFalse);
      expect(vm.error, contains('already'));
      expect(repo.lastCreated, isNull);
    });

    test('a finished request frees the cloth for rebooking', () async {
      final at = _day(11);
      final repo = _ConflictAppointmentRepository(
        appointments: [
          _appt(
              id: 'a1',
              at: at,
              status: Appointment.statusCompleted,
              itemId: 'i1'),
        ],
        booked: const [],
      );
      final vm = BookingViewModel(repo);
      addTearDown(vm.dispose);
      await vm.init();
      await vm.selectDate(DateTime(at.year, at.month, at.day + 1));
      vm.selectSlot('2:00 PM');

      final ok = await vm.confirm(
        userId: 'u1',
        userName: 'Maria',
        itemId: 'i1',
        itemName: 'Gown',
      );

      expect(ok, isTrue);
      expect(repo.lastCreated, isNotNull);
    });

    test('duplicate refusal flags snackbar-only, other errors do not', () async {
      // Duplicate path.
      final at = _day(11);
      final dupRepo = _ConflictAppointmentRepository(
        appointments: [
          _appt(
              id: 'a1',
              at: at,
              status: Appointment.statusPending,
              itemId: 'i1'),
        ],
        booked: const [],
      );
      final dupVm = BookingViewModel(dupRepo);
      addTearDown(dupVm.dispose);
      await dupVm.init();
      await dupVm.selectDate(DateTime(at.year, at.month, at.day));
      dupVm.selectSlot('11:00 AM');
      expect(
          await dupVm.confirm(
              userId: 'u1', userName: 'Maria', itemId: 'i1'),
          isFalse);
      expect(dupVm.duplicateRequest, isTrue);

      // Ordinary failure path leaves the flag down (stale slot taken).
      final plainRepo = _ConflictAppointmentRepository(
        appointments: const [],
        booked: const [],
      );
      final plainVm = BookingViewModel(plainRepo);
      addTearDown(plainVm.dispose);
      await plainVm.init();
      plainVm.selectSlot('2:00 PM');
      plainRepo.booked = const ['2:00 PM'];
      expect(await plainVm.confirm(userId: 'u1', userName: 'Maria'),
          isFalse);
      expect(plainVm.error, contains('just taken'));
      expect(plainVm.duplicateRequest, isFalse);
    });

    test('cancelled slots do not block rebooking', () async {
      final ds = MockAppointmentDataSource();
      final day = DateTime.now().add(const Duration(days: 4));
      final at = DateTime(day.year, day.month, day.day, 11);
      await ds.createAppointment(
          _appt(id: 'old', at: at, status: Appointment.statusCancelled));

      final slots = await ds.bookedSlotsFor(
          DateTime(at.year, at.month, at.day));

      expect(slots, isEmpty);
    });

    test('pending requests block their slot', () async {
      final ds = MockAppointmentDataSource();
      final day = DateTime.now().add(const Duration(days: 5));
      final at = DateTime(day.year, day.month, day.day, 11);
      await ds.createAppointment(
          _appt(id: 'live', at: at, status: Appointment.statusPending));

      final slots = await ds.bookedSlotsFor(
          DateTime(at.year, at.month, at.day));

      expect(slots, contains('11:00 AM'));
    });
  });
}
