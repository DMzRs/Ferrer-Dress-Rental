import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/viewmodels/booking_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/widgets/month_calendar.dart';

class BookingScreenArgs {
  final String? itemId;
  final String? itemName;

  const BookingScreenArgs({this.itemId, this.itemName});
}

class BookingScreen extends StatefulWidget {
  final BookingScreenArgs args;

  const BookingScreen({super.key, this.args = const BookingScreenArgs()});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final BookingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().user;
    _viewModel = context.read<BookingViewModel>();
    if (user != null) {
      _viewModel.watchUserAppointments(user.uid);
    }
    _viewModel.init();
  }

  Future<void> _confirm() async {
    final user = context.read<AuthViewModel>().user;
    if (user == null) return;
    final ok = await _viewModel.confirm(
      userId: user.uid,
      userName: user.fullName,
      itemId: widget.args.itemId,
      itemName: widget.args.itemName,
    );
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultSheet(success: ok),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    final itemName = widget.args.itemName;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(itemName == null ? 'Book an Appointment' : 'Book a Fitting'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.creamGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (itemName != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.blushSoft.withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.blush.withValues(alpha: .6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.checkroom_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Fitting appointment for this piece',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              MonthCalendar(
                selectedDate: vm.selectedDate,
                onSelect: vm.selectDate,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text('Available Time Slots',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  StatusBadge(
                    label: Formatters.monthDay(vm.selectedDate),
                    color: AppColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (vm.isLoadingSlots)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(color: AppColors.rose),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final slot in TimeSlots.labels)
                      _SlotChip(
                        label: slot,
                        state: vm.bookedSlots.contains(slot)
                            ? _SlotState.booked
                            : vm.selectedSlot == slot
                                ? _SlotState.selected
                                : _SlotState.idle,
                        onTap: () => vm.selectSlot(slot),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              Text('Purpose of Visit',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _PurposeDropdown(vm: vm),
              const SizedBox(height: 30),
              GradientButton(
                label: 'Confirm Appointment',
                busy: vm.isConfirming,
                onPressed: vm.canConfirm
                    ? _confirm
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please choose a date and time slot first.'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SlotState { idle, selected, booked }

class _SlotChip extends StatelessWidget {
  final String label;
  final _SlotState state;
  final VoidCallback onTap;

  const _SlotChip({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = state == _SlotState.selected;
    final isBooked = state == _SlotState.booked;
    return GestureDetector(
      onTap: isBooked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.brandGradient : null,
          color: isBooked
              ? AppColors.champagne.withValues(alpha: .5)
              : isSelected
                  ? null
                  : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isBooked
                ? AppColors.champagne
                : isSelected
                    ? Colors.transparent
                    : AppColors.goldSoft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBooked
                  ? Icons.lock_outline_rounded
                  : Icons.schedule_rounded,
              size: 15,
              color: isBooked
                  ? AppColors.inkSoft.withValues(alpha: .55)
                  : isSelected
                      ? Colors.white
                      : AppColors.rose,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isBooked
                    ? AppColors.inkSoft.withValues(alpha: .5)
                    : isSelected
                        ? Colors.white
                        : AppColors.ink,
                decoration: isBooked ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurposeDropdown extends StatelessWidget {
  final BookingViewModel vm;

  const _PurposeDropdown({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldSoft),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vm.purpose,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.roseDark),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          items: [
            for (final purpose in Appointment.purposes)
              DropdownMenuItem(
                value: purpose,
                child: Row(
                  children: [
                    Icon(
                      purpose == 'Measuring'
                          ? Icons.square_foot_rounded
                          : Icons.style_rounded,
                      size: 18,
                      color: AppColors.rose,
                    ),
                    const SizedBox(width: 10),
                    Text(purpose,
                        style: const TextStyle(
                            fontSize: 14.5, color: AppColors.ink)),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) vm.selectPurpose(value);
          },
        ),
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final bool success;

  const _ResultSheet({required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: success
                  ? AppColors.brandGradient
                  : LinearGradient(colors: [
                      AppColors.danger.withValues(alpha: .7),
                      AppColors.danger,
                    ]),
            ),
            child: Icon(
              success ? Icons.check_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            success ? 'Appointment Confirmed' : 'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            success
                ? "We can't wait to see you! A reminder will be sent before your visit."
                : 'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: success ? 'Done' : 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}



