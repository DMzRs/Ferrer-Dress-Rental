import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/notifications/domain/app_notification.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';

/// Appointments this close count as needing attention.
const attentionAppointmentWindow = Duration(hours: 48);

/// Builds the user activity feed, newest first (capped). Steady states that
/// carry no news (plain active rentals) are skipped; cancelled items are
/// skipped — the user cancelled them, nothing to announce.
List<AppNotification> buildNotifications(
  List<Rental> rentals,
  List<Appointment> appointments,
) {
  final out = <AppNotification>[];

  for (final rental in rentals) {
    if (rental.isOverdue) {
      out.add(AppNotification(
        id: 'rental:${rental.id}:overdue',
        title: 'Overdue — ${rental.itemName}',
        subtitle: 'Please return it as soon as possible.',
        at: rental.endDate,
        kind: NotificationKind.overdue,
        attention: true,
        rental: rental,
      ));
    } else if (rental.isDueSoon) {
      out.add(AppNotification(
        id: 'rental:${rental.id}:due',
        title: '${rental.itemName} due soon',
        subtitle: 'Due ${Formatters.shortDate(rental.endDate)}.',
        at: rental.endDate,
        kind: NotificationKind.dueSoon,
        attention: true,
        rental: rental,
      ));
    } else if (rental.isPending) {
      out.add(AppNotification(
        id: 'rental:${rental.id}:pending',
        title: 'Awaiting confirmation',
        subtitle: '${rental.itemName} is being reviewed by the shop.',
        at: rental.createdAt,
        kind: NotificationKind.pendingRental,
        attention: false,
        rental: rental,
      ));
    } else if (rental.isCompleted) {
      out.add(AppNotification(
        id: 'rental:${rental.id}:returned',
        title: 'Returned — ${rental.itemName}',
        subtitle: 'How was it? You can rate it from My Rentals.',
        at: rental.returnedAt ?? rental.updatedAt ?? rental.createdAt,
        kind: NotificationKind.returnInfo,
        attention: false,
        rental: rental,
      ));
    } else if (rental.isDeclined) {
      out.add(AppNotification(
        id: 'rental:${rental.id}:declined',
        title: 'Request declined',
        subtitle: rental.declineReason.trim().isNotEmpty
            ? '${rental.itemName}: ${rental.declineReason.trim()}'
            : '${rental.itemName} was declined. Your payment will be refunded.',
        at: rental.updatedAt ?? rental.createdAt,
        kind: NotificationKind.rentalUpdate,
        attention: false,
        rental: rental,
      ));
    }
  }

  for (final appointment in appointments) {
    if (appointment.status == Appointment.statusCancelled) continue;
    final soon = appointment.isUpcoming &&
        appointment.scheduledAt
            .isBefore(DateTime.now().add(attentionAppointmentWindow));
    if (appointment.isUpcoming) {
      out.add(AppNotification(
        id: 'appt:${appointment.id}:upcoming',
        title: '${appointment.purpose} fitting soon',
        subtitle:
            '${Formatters.monthDay(appointment.scheduledAt)} · ${appointment.itemName?.isNotEmpty == true ? appointment.itemName : 'Ferrer shop'}',
        at: appointment.scheduledAt,
        kind: soon
            ? NotificationKind.appointmentSoon
            : NotificationKind.appointmentInfo,
        attention: soon,
        appointment: appointment,
      ));
    } else {
      out.add(AppNotification(
        id: 'appt:${appointment.id}:${appointment.status}',
        title: 'Appointment ${appointment.statusLabel.toLowerCase()}',
        subtitle: appointment.itemName?.isNotEmpty == true
            ? (appointment.itemName as String)
            : 'See Bookings for details.',
        at: appointment.updatedAt ?? appointment.createdAt,
        kind: NotificationKind.appointmentInfo,
        attention: false,
        appointment: appointment,
      ));
    }
  }

  out.sort((a, b) {
    final byTime = b.at.compareTo(a.at);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  });
  return out.take(30).toList();
}

/// Bubble count: actionable items only.
int attentionCount(List<AppNotification> notifications) =>
    notifications.where((n) => n.attention).length;
