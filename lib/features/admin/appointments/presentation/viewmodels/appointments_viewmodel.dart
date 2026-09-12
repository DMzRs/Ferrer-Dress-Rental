import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';

/// Admin-side appointment requests. Confirming a request that is tied to a
/// product also flips that product to 'scheduled_for_appointment'.
class AppointmentsViewModel extends ChangeNotifier {
  AppointmentsViewModel(this._appointmentRepository, this._inventoryRepository) {
    _subscription =
        _appointmentRepository.allAppointmentsStream().listen(_onAppointments);
  }

  final AppointmentRepository _appointmentRepository;
  final InventoryRepository _inventoryRepository;

  StreamSubscription<List<Appointment>>? _subscription;

  List<Appointment> _appointments = [];
  bool _loading = true;
  String _busyId = '';

  /// Selected tab: 0 requests, 1 scheduled, 2 resolved. Mirrors the
  /// TabController in the screen so dashboard deep-links can target a tab.
  int _tab = 0;
  int get tab => _tab;

  /// Record id to spotlight (from a dashboard deep-link). Cleared whenever
  /// the tab changes.
  String? _highlightId;
  String? get highlightId => _highlightId;

  void setTab(int value) {
    _tab = value.clamp(0, 2);
    _highlightId = null;
    notifyListeners();
  }

  void highlight(String appointmentId) {
    _highlightId = appointmentId;
    notifyListeners();
  }

  List<Appointment> get requests {
    final pending = _appointments
        .where((a) => a.status == Appointment.statusPending)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return pending;
  }

  List<Appointment> get scheduled {
    final confirmed = _appointments
        .where((a) =>
            a.status == Appointment.statusConfirmed || a.status == 'scheduled')
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return confirmed;
  }

  List<Appointment> get resolved {
    final done = _appointments
        .where((a) =>
            a.status == Appointment.statusDeclined ||
            a.status == Appointment.statusCancelled ||
            a.status == Appointment.statusCompleted ||
            a.status == Appointment.statusNoShow)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return done;
  }

  int get pendingCount => requests.length;

  bool get isLoading => _loading;

  bool get isBusy => _busyId.isNotEmpty;

  bool isBusyFor(String appointmentId) => _busyId == appointmentId;

  void _onAppointments(List<Appointment> appointments) {
    _appointments = appointments;
    _loading = false;
    notifyListeners();
  }

  /// Confirms the request and, when it targets a product, marks that product
  /// as scheduled for appointment.
  Future<bool> confirm(Appointment appointment) async {
    _busyId = appointment.id;
    notifyListeners();
    try {
      await _appointmentRepository.updateStatus(
          appointment.id, Appointment.statusConfirmed);
      final itemId = appointment.itemId;
      if (itemId != null && itemId.isNotEmpty) {
        await _inventoryRepository.updateStatus(
            itemId, 'scheduled_for_appointment');
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _busyId = '';
      notifyListeners();
    }
  }

  /// Records the visit verdict for a scheduled appointment and frees the
  /// product back to available so it can be rented again.
  Future<bool> complete(String appointmentId) =>
      _finish(appointmentId, Appointment.statusCompleted);

  /// Records a no-show and frees the product back to available.
  Future<bool> markNoShow(String appointmentId) =>
      _finish(appointmentId, Appointment.statusNoShow);

  Future<bool> _finish(String appointmentId, String status) async {
    _busyId = appointmentId;
    notifyListeners();
    try {
      await _appointmentRepository.updateStatus(appointmentId, status);
      await _freeItemIfScheduled(appointmentId);
      return true;
    } catch (_) {
      return false;
    } finally {
      _busyId = '';
      notifyListeners();
    }
  }

  Future<void> _freeItemIfScheduled(String appointmentId) async {
    final match = _appointments.where((a) => a.id == appointmentId).toList();
    if (match.isEmpty) return;
    final itemId = match.first.itemId;
    if (itemId == null || itemId.isEmpty) return;
    final items = await _inventoryRepository.itemsStream().first;
    final item = items.where((i) => i.id == itemId).toList();
    if (item.isEmpty || item.first.status != 'scheduled_for_appointment') {
      return;
    }
    await _inventoryRepository.updateStatus(itemId, 'available');
  }

  /// Declines the request with the admin's reason; the user sees it.
  Future<bool> decline(Appointment appointment, String reason) async {
    if (reason.trim().isEmpty) return false;
    _busyId = appointment.id;
    notifyListeners();
    try {
      await _appointmentRepository.updateStatus(
        appointment.id,
        Appointment.statusDeclined,
        declineReason: reason,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _busyId = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
