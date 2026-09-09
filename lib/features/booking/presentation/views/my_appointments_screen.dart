import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/viewmodels/my_appointments_viewmodel.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyAppointmentsViewModel>();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.creamGradient),
      child: SafeArea(
        bottom: false,
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.rose))
            : DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
                      child: Text(
                        'Appointments',
                        style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        'Your fitting schedule with our atelier',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TabBar(
                      labelColor: AppColors.roseDark,
                      unselectedLabelColor: AppColors.inkSoft,
                      indicatorColor: AppColors.rose,
                      labelStyle:
                          const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Upcoming'),
                        Tab(text: 'History'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _list(context, vm.upcoming),
                          _list(context, vm.history),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Appointment> items) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No appointments here',
        subtitle: 'Book a fitting from any dress you love.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _AppointmentTile(appointment: items[index]),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final declined = appointment.status == Appointment.statusDeclined;
    final cancelled = appointment.status == Appointment.statusCancelled;
    final color = declined || cancelled
        ? AppColors.danger
        : appointment.status == Appointment.statusPending
            ? AppColors.gold
            : AppColors.success;
    final label = appointment.statusLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.champagne.withValues(alpha: .9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blush.withValues(alpha: .16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: declined || cancelled
                  ? const LinearGradient(colors: [AppColors.danger, AppColors.danger])
                  : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              appointment.purpose == 'Measuring'
                  ? Icons.square_foot_rounded
                  : Icons.style_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment.purpose,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    StatusBadge(label: label, color: color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.monthDay(appointment.scheduledAt)} · ${TimeOfDay.fromDateTime(appointment.scheduledAt).format(context)}',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft.withValues(alpha: .95)),
                ),
                if (appointment.itemName != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    appointment.itemName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.roseDark.withValues(alpha: .85),
                    ),
                  ),
                ],
                if (declined && appointment.declineReason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Reason: ${appointment.declineReason}',
                    style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

