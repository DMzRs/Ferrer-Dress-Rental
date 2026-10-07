import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/booking/data/datasources/appointment_data_source.dart';
import 'package:ferrer_rental_shop/features/booking/data/datasources/firebase_appointment_data_source.dart';
import 'package:ferrer_rental_shop/features/booking/data/datasources/mock_appointment_data_source.dart';

/// Routes appointment calls to the active data source.
class AppointmentRepositoryImpl implements AppointmentRepository {
  const AppointmentRepositoryImpl(this._dataSource);

  final AppointmentDataSource _dataSource;

  /// Returns the Firebase or mock source per app config.
  static AppointmentDataSource defaultDataSource() => AppConfig.firebaseEnabled
      ? FirebaseAppointmentDataSource()
      : MockAppointmentDataSource();

  /// Streams appointments for one user.
  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) =>
      _dataSource.userAppointmentsStream(userId);

  /// Streams all appointments.
  @override
  Stream<List<Appointment>> allAppointmentsStream() =>
      _dataSource.allAppointmentsStream();

  /// Streams recent appointments up to [limit].
  @override
  Stream<List<Appointment>> pagedAppointmentsStream({int limit = 20}) =>
      _dataSource.pagedAppointmentsStream(limit: limit);

  /// Loads taken time-slot labels for a calendar day.
  @override
  Future<List<String>> bookedSlotsFor(DateTime day) =>
      _dataSource.bookedSlotsFor(day);

  /// Creates an appointment.
  @override
  Future<void> createAppointment(Appointment appointment) =>
      _dataSource.createAppointment(appointment);

  /// Marks an appointment as cancelled.
  @override
  Future<void> cancelAppointment(String appointmentId) =>
      _dataSource.cancelAppointment(appointmentId);

  /// Updates status and optional decline reason.
  @override
  Future<void> updateStatus(
    String appointmentId,
    String status, {
    String? declineReason,
  }) =>
      _dataSource.updateStatus(appointmentId, status,
          declineReason: declineReason);
}

