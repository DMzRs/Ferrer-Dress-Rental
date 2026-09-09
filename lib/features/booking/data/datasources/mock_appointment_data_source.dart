import 'dart:async';

import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/data/models/appointment_model.dart';
import 'appointment_data_source.dart';

class MockAppointmentDataSource implements AppointmentDataSource {
  final List<Appointment> _appointments = [];
  final StreamController<List<Appointment>> _controller =
      StreamController<List<Appointment>>.broadcast();
  bool _seeded = false;

  static const List<String> slotLabels = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  void _ensureSeed() {
    if (_seeded) return;
    _seeded = true;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _appointments.addAll([
      AppointmentModel(
        id: 'apt-01',
        userId: 'user-001',
        userName: 'Maria Santos',
        itemId: 'itm-10',
        itemName: 'Pearl White Debut Gown',
        purpose: 'Trying On',
        scheduledAt:
            DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10),
        status: 'scheduled',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppointmentModel(
        id: 'apt-02',
        userId: 'user-002',
        userName: 'Angela Reyes',
        itemId: null,
        itemName: null,
        purpose: 'Measuring',
        scheduledAt: DateTime(now.year, now.month, now.day + 3, 14),
        status: 'scheduled',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ]);
    scheduleMicrotask(() {
      if (!_controller.isClosed) {
        _controller.add(List.unmodifiable(_appointments));
      }
    });
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_appointments));
    }
  }

  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) async* {
    _ensureSeed();
    await Future.delayed(const Duration(milliseconds: 250));
    yield _appointments.where((a) => a.userId == userId).toList();
    await for (final list in _controller.stream) {
      yield list.where((a) => a.userId == userId).toList();
    }
  }

  @override
  Stream<List<Appointment>> allAppointmentsStream() async* {
    _ensureSeed();
    await Future.delayed(const Duration(milliseconds: 250));
    yield List.unmodifiable(_appointments);
    yield* _controller.stream;
  }

  @override
  Future<List<String>> bookedSlotsFor(DateTime day) async {
    _ensureSeed();
    await Future.delayed(const Duration(milliseconds: 200));
    final sameDay = _appointments.where((a) {
      final d = a.scheduledAt;
      final target = DateTime(d.year, d.month, d.day);
      final query = DateTime(day.year, day.month, day.day);
      if (target != query) return false;
      return a.status == 'scheduled';
    });
    return sameDay.map(_labelFor).toList();
  }

  String _labelFor(Appointment a) {
    final index = a.scheduledAt.hour.clamp(0, slotLabels.length - 1);
    return slotLabels[index];
  }

  @override
  Future<void> createAppointment(Appointment appointment) async {
    _ensureSeed();
    await Future.delayed(const Duration(milliseconds: 500));
    final id = 'apt-${DateTime.now().millisecondsSinceEpoch}';
    _appointments.insert(
      0,
      AppointmentModel.fromEntity(appointment).copyWith(id: id),
    );
    _emit();
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _appointments[index] =
          AppointmentModel.fromEntity(_appointments[index]).copyWith(status: 'cancelled');
      _emit();
    }
  }

  @override
  Future<void> updateStatus(
    String appointmentId,
    String status, {
    String? declineReason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _appointments[index] = AppointmentModel.fromEntity(_appointments[index])
          .copyWith(
              status: status,
              clearDeclineReason: declineReason == null,
              declineReason: declineReason);
      _emit();
    }
  }
}

