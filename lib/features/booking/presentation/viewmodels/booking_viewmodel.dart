import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';

class BookingViewModel extends ChangeNotifier {
  BookingViewModel(this._repository);

  final AppointmentRepository _repository;
  StreamSubscription? _sub;

  DateTime _selectedDate = _tomorrow();
  String? _selectedSlot;
  String _purpose = Appointment.purposes.first;
  List<String> _bookedSlots = const [];
  bool _loadingSlots = true;
  bool _confirming = false;

  static const List<String> allSlots = TimeSlots.labels;

  DateTime get selectedDate => _selectedDate;
  String? get selectedSlot => _selectedSlot;
  String get purpose => _purpose;
  List<String> get bookedSlots => _bookedSlots;
  bool get isLoadingSlots => _loadingSlots;
  bool get isConfirming => _confirming;
  bool get canConfirm => _selectedSlot != null && !_confirming && !_loadingSlots;

  List<String> get availableSlots =>
      allSlots.where((s) => !_bookedSlots.contains(s)).toList();

  static DateTime _tomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  void watchUserAppointments(String userId) {
    _sub ??= _repository.userAppointmentsStream(userId).listen((_) {});
  }

  Future<void> init() => _loadSlots();

  Future<void> selectDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized == _selectedDate) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (normalized.isBefore(today)) {
      _error = 'Cannot select a past date.';
      notifyListeners();
      return;
    }
    _error = null;
    _selectedDate = normalized;
    _selectedSlot = null;
    notifyListeners();
    await _loadSlots();
  }

  Future<void> _loadSlots() async {
    _loadingSlots = true;
    notifyListeners();
    try {
      _bookedSlots = await _repository.bookedSlotsFor(_selectedDate);
    } catch (_) {
      _bookedSlots = const [];
    }
    _loadingSlots = false;
    notifyListeners();
  }

  void selectSlot(String slot) {
    if (_bookedSlots.contains(slot)) return;
    _error = null;
    _selectedSlot = slot;
    notifyListeners();
  }

  void selectPurpose(String purpose) {
    _purpose = purpose;
    notifyListeners();
  }

  Future<bool> confirm({
    required String userId,
    required String userName,
    String? itemId,
    String? itemName,
  }) async {
    if (_selectedSlot == null) {
      _error = 'Please choose a date and time slot first.';
      notifyListeners();
      return false;
    }
    _error = null;
    _confirming = true;
    notifyListeners();

    final scheduledAt =
        _combineDateAndSlot(_selectedDate, _selectedSlot!);
    // No back-scheduling: block past dates/times (e.g. stale selection kept
    // overnight, or a same-day slot that already passed).
    if (!scheduledAt.isAfter(DateTime.now())) {
      _error = 'Cannot book an appointment in the past. Please pick a future date and time.';
      _confirming = false;
      notifyListeners();
      return false;
    }
    final appointment = Appointment(
      id: '',
      userId: userId,
      userName: userName,
      itemId: itemId,
      itemName: itemName,
      purpose: _purpose,
      scheduledAt: scheduledAt,
      status: Appointment.statusPending,
      createdAt: DateTime.now(),
    );

    try {
      await _repository.createAppointment(appointment);
      return true;
    } on Failure catch (failure) {
      _error = failure.message;
      return false;
    } catch (_) {
      _error = 'Could not book your appointment. Please try again.';
      return false;
    } finally {
      _confirming = false;
      notifyListeners();
    }
  }

  String? _error;
  String? get error => _error;

  DateTime _combineDateAndSlot(DateTime date, String slot) {
    final hour = TimeSlots.hours[allSlots.indexOf(slot)];
    return DateTime(date.year, date.month, date.day, hour);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class TimeSlots {
  static const labels = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  static const hours = [9, 10, 11, 13, 14, 15, 16];
}

