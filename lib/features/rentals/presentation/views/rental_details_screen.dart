import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/cancel_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/viewmodels/rental_details_viewmodel.dart';

class RentalDetailsScreen extends StatelessWidget {
  final Rental rental;

  const RentalDetailsScreen({super.key, required this.rental});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RentalDetailsViewModel(
        context.read<CancelRentalUseCase>(),
      ),
      child: _Body(rental: rental),
    );
  }
}

class _Body extends StatelessWidget {
  final Rental rental;

  const _Body({required this.rental});

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cancel this rental?',
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700)),
        content: const Text(
          'Your full payment including the security deposit will be refunded within 3-5 banking days.',
          style: TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child:
                const Text('Keep Rental', style: TextStyle(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final vm = context.read<RentalDetailsViewModel>();
    final ok = await vm.cancel(rental);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Rental cancelled. Refund is on its way.'
            : 'Could not cancel right now. Please try again.'),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RentalDetailsViewModel>();
    final (_, statusColor) =
        StatusBadge.resolve(rental.displayStatus, rental.endDate);
    final canCancel = (rental.isPending || rental.isActive) && !rental.isOverdue;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Rental Details'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.creamGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .95),
                  borderRadius: BorderRadius.circular(26),
                  border:
                      Border.all(color: AppColors.goldSoft.withValues(alpha: .7)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blush.withValues(alpha: .25),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ItemThumbnail(
                          imageUrls: const [],
                          name: rental.itemName,
                          width: 96,
                          height: 122,
                          borderRadius: BorderRadius.circular(18),
                          gradientSeed: rental.itemId.hashCode,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusBadge(
                                label: StatusBadge.resolve(
                                        rental.displayStatus, rental.endDate)
                                    .$1,
                                color: statusColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                rental.itemName,
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Rented by ${rental.userName}',
                                style: const TextStyle(
                                    fontSize: 12.5, color: AppColors.inkSoft),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Timeline(rental: rental),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('Payment Summary',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .95),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.champagne),
                ),
                child: Column(
                  children: [
                    _row('Rental Fee', '₱${rental.rentalFee.toStringAsFixed(0)}'),
                    const SizedBox(height: 12),
                    _row(
                      'Security Deposit',
                      '₱${rental.securityDeposit.toStringAsFixed(0)}',
                      note: rental.isCompleted ? 'Refunded' : 'Held',
                      noteColor:
                          rental.isCompleted ? AppColors.success : AppColors.gold,
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.champagne),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                        Text(
                          '₱${rental.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.champagne.withValues(alpha: .4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.goldSoft),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.gold),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        rental.isPending
                            ? 'We received your payment and the shop is reviewing your rental. You will see it as Active once confirmed — you can still cancel for a full refund in the meantime.'
                            : rental.isDeclined
                                ? 'This rental request was declined by the shop. Your full payment will be refunded within 3-5 banking days.'
                                : rental.isOverdue
                                    ? 'This rental is past its due date. A late fee may apply to your deposit refund - please visit the shop or contact us right away.'
                                    : 'Please return the item clean and on time so your full security deposit can be refunded.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.ink.withValues(alpha: .85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (canCancel) ...[
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side:
                          BorderSide(color: AppColors.danger.withValues(alpha: .55)),
                    ),
                    icon: vm.busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancel Rental'),
                    onPressed: vm.busy ? null : () => _cancel(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {String? note, Color noteColor = AppColors.success}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
        if (note != null) ...[
          const SizedBox(width: 7),
          StatusBadge(label: note, color: noteColor),
        ],
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final Rental rental;

  const _Timeline({required this.rental});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _milestone(Icons.event_available_rounded, 'Booked on',
            Formatters.date(rental.createdAt)),
        _divider(),
        _milestone(Icons.play_circle_outline_rounded, 'Rental start',
            Formatters.date(rental.startDate)),
        _divider(),
        _milestone(Icons.flag_rounded, 'Return by', Formatters.date(rental.endDate),
            highlight: true),
        if (rental.returnedAt != null) ...[
          _divider(),
          _milestone(
              Icons.task_alt_rounded, 'Returned', Formatters.date(rental.returnedAt!)),
        ],
      ],
    );
  }

  Widget _milestone(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: highlight ? AppColors.blushSoft : AppColors.cream,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 16,
              color: highlight ? AppColors.roseDark : AppColors.inkSoft),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.roseDark : AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.only(left: 15),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 1.4,
            height: 16,
            color: AppColors.champagne,
          ),
        ),
      );
}
