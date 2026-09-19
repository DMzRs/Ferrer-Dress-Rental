import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';

abstract class AppointmentRepository {
  Stream<List<Appointment>> userAppointmentsStream(String userId);

  Stream<List<Appointment>> allAppointmentsStream();

  /// Paged admin feed, newest first. Defaults to the full stream; remote
  /// sources override with a server-side limit.
  Stream<List<Appointment>> pagedAppointmentsStream({int limit = 20}) =>
      allAppointmentsStream();

  Future<List<String>> bookedSlotsFor(DateTime day);

  Future<void> createAppointment(Appointment appointment);

  Future<void> cancelAppointment(String appointmentId);

  /// Admin lifecycle: confirm / decline (with reason) / etc.
  Future<void> updateStatus(
    String appointmentId,
    String status, {
    String? declineReason,
  });
}

