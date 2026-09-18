import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/router/app_router.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/viewmodels/my_appointments_viewmodel.dart';
import 'package:ferrer_rental_shop/features/notifications/domain/app_notification.dart';
import 'package:ferrer_rental_shop/features/notifications/domain/notifications_builder.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/viewmodels/my_rentals_viewmodel.dart';

class NotificationsScreen extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTo;

  const NotificationsScreen({super.key, this.onNavigateTo});

  @override
  Widget build(BuildContext context) {
    final rentalsVm = context.watch<MyRentalsViewModel>();
    final appointmentsVm = context.watch<MyAppointmentsViewModel>();
    final items = buildNotifications(
      rentalsVm.allRentalsForNotifications,
      appointmentsVm.allAppointmentsForNotifications,
    );

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.creamGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                'Notifications',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                'Updates on your rentals and fittings',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No activity yet.\nRental and fitting updates will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.inkSoft, fontSize: 14, height: 1.5),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(20, 6, 20, 110),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => _Row(
                        notification: items[index],
                        onNavigateTo: onNavigateTo,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final AppNotification notification;
  final void Function(int tabIndex)? onNavigateTo;

  const _Row({required this.notification, this.onNavigateTo});

  void _open(BuildContext context) {
    final rental = notification.rental;
    if (rental != null) {
      context.pushNamed(AppRoutes.rentalDetails, arguments: rental);
      return;
    }
    if (notification.appointment != null) {
      onNavigateTo?.call(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (notification.kind) {
      NotificationKind.overdue =>
        (Icons.warning_rounded, AppColors.danger),
      NotificationKind.dueSoon =>
        (Icons.schedule_rounded, AppColors.gold),
      NotificationKind.pendingRental =>
        (Icons.hourglass_top_rounded, AppColors.gold),
      NotificationKind.rentalUpdate =>
        (Icons.info_outline_rounded, AppColors.roseDark),
      NotificationKind.returnInfo =>
        (Icons.task_alt_rounded, AppColors.success),
      NotificationKind.appointmentSoon =>
        (Icons.event_available_rounded, AppColors.roseDark),
      NotificationKind.appointmentInfo =>
        (Icons.event_note_outlined, AppColors.inkSoft),
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.attention
                ? AppColors.danger.withValues(alpha: .45)
                : AppColors.champagne.withValues(alpha: .8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.timeAgo(notification.at),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.inkSoft.withValues(alpha: .8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
