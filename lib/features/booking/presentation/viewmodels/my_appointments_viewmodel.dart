import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/audit/domain/audit_logger.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';

class MyAppointmentsViewModel extends ChangeNotifier {
  MyAppointmentsViewModel(
    this._repository,
    this._authRepository, {
    this._inventory,
    this._audit,
  }) {
    _authSub = _authRepository.authStateChanges.listen((user) {
      _userId = user?.uid;
      _sub?.cancel();
      if (_userId != null) {
        _sub =
            _repository.userAppointmentsStream(_userId!).listen(_onAppointments);
      }
    });
  }

  final AppointmentRepository _repository;
  final AuthRepository _authRepository;

  /// Item lookup that frees scheduled garments on cancel. Absent in legacy
  /// callers, which keep the old cancel-only behavior.
  final InventoryRepository? _inventory;
  final AuditLogger? _audit;

  StreamSubscription? _authSub;
  StreamSubscription<List<Appointment>>? _sub;
  String? _userId;

  List<Appointment> _appointments = const [];
  bool _loading = true;
  bool _cancellingId = false;

  List<Appointment> get upcoming => _sorted.where((a) => a.isUpcoming).toList();
  List<Appointment> get history =>
      _sorted.where((a) => !a.isUpcoming).toList();
  bool get isLoading => _loading;

  /// Unfiltered list for the notifications feed.
  List<Appointment> get allAppointmentsForNotifications =>
      List.unmodifiable(_appointments);

  bool get isCancelling => _cancellingId;

  Iterable<Appointment> get _sorted {
    final copy = [..._appointments];
    copy.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return copy;
  }

  void _onAppointments(List<Appointment> appointments) {
    _appointments = appointments;
    _loading = false;
    notifyListeners();
  }

  Future<bool> cancel(Appointment appointment) async {
    _cancellingId = true;
    notifyListeners();
    try {
      await _repository.cancelAppointment(appointment.id);
      await _freeItemIfScheduled(appointment);
      await _audit?.log('appointment.cancelled',
          targetType: 'appointment', targetId: appointment.id);
      return true;
    } catch (_) {
      return false;
    } finally {
      _cancellingId = false;
      notifyListeners();
    }
  }

  /// Releases the linked garment when it was held for this appointment,
  /// so a cancelled visit never strands an item as scheduled.
  Future<void> _freeItemIfScheduled(Appointment appointment) async {
    final inventory = _inventory;
    final itemId = appointment.itemId;
    if (inventory == null || itemId == null || itemId.isEmpty) return;
    final items = await inventory.itemsStream().first;
    final match = items.where((i) => i.id == itemId).toList();
    if (match.isEmpty || match.first.status != 'scheduled_for_appointment') {
      return;
    }
    await inventory.updateStatus(itemId, 'available');
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}


