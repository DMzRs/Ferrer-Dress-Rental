import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';

class MyAppointmentsViewModel extends ChangeNotifier {
  MyAppointmentsViewModel(this._repository, this._authRepository) {
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
      return true;
    } catch (_) {
      return false;
    } finally {
      _cancellingId = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}


