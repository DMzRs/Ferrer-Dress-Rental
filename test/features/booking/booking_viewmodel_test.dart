import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAppointmentRepository implements AppointmentRepository {
  List<String> booked = [];
  bool throwOnSlots = false;
  bool throwFailureOnCreate = false;
  bool throwUnknownOnCreate = false;
  Appointment? lastCreated;

  @override
  Future<List<String>> bookedSlotsFor(DateTime day) async {
    if (throwOnSlots) throw Exception('slots down');
    return booked;
  }

  @override
  Future<void> createAppointment(Appointment a) async {
    if (throwFailureOnCreate) throw const NetworkFailure('slot taken');
    if (throwUnknownOnCreate) throw Exception('boom');
    lastCreated = a;
  }

  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) =>
      const Stream.empty();

  @override
  Stream<List<Appointment>> allAppointmentsStream() => const Stream.empty();

  @override
  Future<void> cancelAppointment(String id) async {}

  @override
  Future<void> updateStatus(String id, String status,
      {String? declineReason}) async {}
}

void main() {
  group('BookingViewModel slots', () {
    test('init loads booked slots and exposes available ones', () async {
      final repo = FakeAppointmentRepository()
        ..booked = ['9:00 AM', '10:00 AM'];
      final vm = BookingViewModel(repo);
      await vm.init();

      expect(vm.isLoadingSlots, isFalse);
      expect(vm.bookedSlots, ['9:00 AM', '10:00 AM']);
      expect(vm.availableSlots, isNot(contains('9:00 AM')));
      expect(vm.availableSlots, contains('11:00 AM'));
      vm.dispose();
    });

    test('slot load failure falls back to empty booked list', () async {
      final repo = FakeAppointmentRepository()..throwOnSlots = true;
      final vm = BookingViewModel(repo);
      await vm.init();

      expect(vm.isLoadingSlots, isFalse);
      expect(vm.bookedSlots, isEmpty);
      expect(vm.availableSlots, hasLength(TimeSlots.labels.length));
      vm.dispose();
    });

    test('selectSlot ignores booked slots, accepts free ones', () async {
      final repo = FakeAppointmentRepository()..booked = ['9:00 AM'];
      final vm = BookingViewModel(repo);
      await vm.init();

      vm.selectSlot('9:00 AM');
      expect(vm.selectedSlot, isNull);
      expect(vm.canConfirm, isFalse);

      vm.selectSlot('11:00 AM');
      expect(vm.selectedSlot, '11:00 AM');
      expect(vm.canConfirm, isTrue);
      vm.dispose();
    });

    test('selectDate resets slot and reloads', () async {
      final repo = FakeAppointmentRepository();
      final vm = BookingViewModel(repo);
      await vm.init();
      vm.selectSlot('11:00 AM');

      final next = vm.selectedDate.add(const Duration(days: 1));
      await vm.selectDate(next);

      expect(vm.selectedDate, DateTime(next.year, next.month, next.day));
      expect(vm.selectedSlot, isNull);
      vm.dispose();
    });

    test('selectPurpose updates purpose', () async {
      final repo = FakeAppointmentRepository();
      final vm = BookingViewModel(repo);
      vm.selectPurpose('Trying On');
      expect(vm.purpose, 'Trying On');
      vm.dispose();
    });
  });

  group('BookingViewModel.confirm', () {
    test('returns false when no slot selected', () async {
      final vm = BookingViewModel(FakeAppointmentRepository());
      expect(await vm.confirm(userId: 'u1', userName: 'Jane'), isFalse);
      vm.dispose();
    });

    test('creates pending appointment on success', () async {
      final repo = FakeAppointmentRepository();
      final vm = BookingViewModel(repo);
      await vm.init();
      vm.selectSlot('11:00 AM');

      final ok = await vm.confirm(
        userId: 'u1',
        userName: 'Jane',
        itemId: 'i1',
        itemName: 'Gown',
      );

      expect(ok, isTrue);
      expect(repo.lastCreated, isNotNull);
      expect(repo.lastCreated!.status, Appointment.statusPending);
      expect(repo.lastCreated!.userId, 'u1');
      expect(repo.lastCreated!.scheduledAt.hour, 11);
      expect(vm.isConfirming, isFalse);
      vm.dispose();
    });

    test('maps Failure message to error', () async {
      final repo = FakeAppointmentRepository()..throwFailureOnCreate = true;
      final vm = BookingViewModel(repo);
      await vm.init();
      vm.selectSlot('11:00 AM');

      final ok = await vm.confirm(userId: 'u1', userName: 'Jane');

      expect(ok, isFalse);
      expect(vm.error, 'slot taken');
      vm.dispose();
    });

    test('maps unknown errors to generic message', () async {
      final repo = FakeAppointmentRepository()..throwUnknownOnCreate = true;
      final vm = BookingViewModel(repo);
      await vm.init();
      vm.selectSlot('11:00 AM');

      final ok = await vm.confirm(userId: 'u1', userName: 'Jane');

      expect(ok, isFalse);
      expect(vm.error, contains('Could not book'));
      vm.dispose();
    });
  });
}
