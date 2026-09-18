import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';

enum NotificationKind {
  overdue,
  dueSoon,
  pendingRental,
  rentalUpdate,
  returnInfo,
  appointmentSoon,
  appointmentInfo,
}

/// One row in the user Notifications feed. Derived client-side from the
/// rentals + appointments streams (no backend, no read state).
class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final DateTime at;
  final NotificationKind kind;

  /// Counts toward the nav-bar bubble. Only self-clearing states qualify.
  final bool attention;

  final Rental? rental;
  final Appointment? appointment;

  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.at,
    required this.kind,
    required this.attention,
    this.rental,
    this.appointment,
  });
}
