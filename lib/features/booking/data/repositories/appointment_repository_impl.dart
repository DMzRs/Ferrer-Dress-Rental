import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/booking/data/datasources/appointment_data_source.dart';
import 'package:ferrer_rental_shop/features/booking/data/datasources/firebase_appointment_data_source.dart';
import 'package:ferrer_rental_shop/features/booking/data/datasources/mock_appointment_data_source.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  const AppointmentRepositoryImpl(this._dataSource);

  final AppointmentDataSource _dataSource;

  static AppointmentDataSource defaultDataSource() => AppConfig.firebaseEnabled
      ? FirebaseAppointmentDataSource()
      : MockAppointmentDataSource();

  @override
  Stream<List<Appointment>> userAppointmentsStream(String userId) =>
      _dataSource.userAppointmentsStream(userId);

  @override
  Stream<List<Appointment>> allAppointmentsStream() =>
      _dataSource.allAppointmentsStream();

  @override
  Future<List<String>> bookedSlotsFor(DateTime day) =>
      _dataSource.bookedSlotsFor(day);

  @override
  Future<void> createAppointment(Appointment appointment) =>
      _dataSource.createAppointment(appointment);

  @override
  Future<void> cancelAppointment(String appointmentId) =>
      _dataSource.cancelAppointment(appointmentId);

  @override
  Future<void> updateStatus(
    String appointmentId,
    String status, {
    String? declineReason,
  }) =>
      _dataSource.updateStatus(appointmentId, status,
          declineReason: declineReason);
}

