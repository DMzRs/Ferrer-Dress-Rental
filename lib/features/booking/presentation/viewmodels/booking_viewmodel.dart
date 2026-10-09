import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';

/// Holds booking date, slot, and confirmation state.
class BookingViewModel extends ChangeNotifier {
  BookingViewModel(this._repository, {this._inventory});

  final AppointmentRepository _repository;

  /// Item lookup for the maintenance guard. Absent in legacy callers,
  /// which keep the old behavior of booking without an item check.
  final InventoryRepository? _inventory;
  StreamSubscription? _sub;

  DateTime _selectedDate = _tomorrow();
  String? _selectedSlot;
  String _purpose = Appointment.purposes.first;
  List<String> _bookedSlots = const [];
  bool _loadingSlots = true;
  bool _confirming = false;

  /// All bookable time-slot labels.
  static const List<String> allSlots = TimeSlots.labels;

  /// Currently picked calendar day.
  DateTime get selectedDate => _selectedDate;
  /// Currently picked time slot, if any.
  String? get selectedSlot => _selectedSlot;
  /// Chosen visit purpose.
  String get purpose => _purpose;
  /// Taken slot labels for the selected day.
  List<String> get bookedSlots => _bookedSlots;
  /// Whether booked slots are still loading.
  bool get isLoadingSlots => _loadingSlots;
  /// Whether confirmation is in progress.
  bool get isConfirming => _confirming;
  /// Whether the confirm button can be pressed.
  bool get canConfirm => _selectedSlot != null && !_confirming && !_loadingSlots;

  /// Free slot labels for the selected day.
  List<String> get availableSlots =>
      allSlots.where((s) => !_bookedSlots.contains(s)).toList();

  static DateTime _tomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// Keeps the user appointment stream alive for updates.
  void watchUserAppointments(String userId) {
    _sub ??= _repository.userAppointmentsStream(userId).listen((_) {});
  }

  /// Loads booked slots for the selected date.
  Future<void> init() => _loadSlots();

  /// Picks a new date and reloads its booked slots.
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

  /// Picks a free time slot.
  void selectSlot(String slot) {
    if (_bookedSlots.contains(slot)) return;
    _error = null;
    _selectedSlot = slot;
    notifyListeners();
  }

  /// Picks the visit purpose.
  void selectPurpose(String purpose) {
    _purpose = purpose;
    notifyListeners();
  }

  /// Creates the appointment and returns true on success.
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
    // Items under maintenance cannot be tried on, even if the booking
    // screen was opened before the status changed.
    final inventory = _inventory;
    if (itemId != null && itemId.isNotEmpty && inventory != null) {
      bool blocked;
      try {
        final items = await inventory.itemsStream().first;
        blocked = items.any(
            (item) => item.id == itemId && item.status == 'maintenance');
      } catch (_) {
        _error = 'Could not verify this item right now. Please try again.';
        notifyListeners();
        return false;
      }
      if (blocked) {
        _error =
            'This item is under maintenance and cannot be booked for a fitting right now.';
        notifyListeners();
        return false;
      }
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
  /// Latest validation or booking failure message.
  String? get error => _error;

  DateTime _combineDateAndSlot(DateTime date, String slot) {
    final hour = TimeSlots.hours[allSlots.indexOf(slot)];
    return DateTime(date.year, date.month, date.day, hour);
  }

  /// Cancels the stream subscription.
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Shared booking slot labels and hours.
class TimeSlots {
  /// Display labels for bookable slots.
  static const labels = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  /// Hour of day matching each label.
  static const hours = [9, 10, 11, 13, 14, 15, 16];
}

