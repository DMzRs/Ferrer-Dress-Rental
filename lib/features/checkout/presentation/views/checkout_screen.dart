import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/router/app_router.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/create_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/checkout/presentation/viewmodels/checkout_viewmodel.dart';

class CheckoutScreen extends StatelessWidget {
  final CatalogItem item;

  const CheckoutScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckoutViewModel(
        context.read<CreateRentalUseCase>(),
        item,
      ),
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final TextEditingController _addressController =
      TextEditingController(text: context.read<AuthViewModel>().user?.address ?? '');

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final vm = context.read<CheckoutViewModel>();
    final now = DateTime.now();
    final initial = isStart ? vm.startDate : vm.endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.roseDark)),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (isStart) {
      vm.updateStartDate(picked);
    } else {
      vm.updateEndDate(picked);
    }
  }

  Future<void> _payAndConfirm() async {
    final vm = context.read<CheckoutViewModel>();
    final auth = context.read<AuthViewModel>();
    final user = auth.user;
    if (user == null) return;

    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your address so we know where to bring the item.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final ok = await vm.confirm(user, address: address);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.error ?? 'Something went wrong.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    // Remember the address for the next rental; the rental doc already
    // carries its own copy, so a failed save must not block the flow.
    if (address != user.address) {
      unawaited(auth.updateProfile(address: address));
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SuccessSheet(),
    );
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.myRentals, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CheckoutViewModel>();
    final savedPlaces = context.watch<AuthViewModel>().user?.savedPlaces ?? const [];
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.creamGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderSummaryCard(item: vm.item),
              const SizedBox(height: 18),
              Text('Rental Period', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'START DATE',
                      dateText: Formatters.date(vm.startDate),
                      icon: Icons.event_outlined,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 17, color: AppColors.rose.withValues(alpha: .7)),
                  ),
                  Expanded(
                    child: _DateField(
                      label: 'END DATE',
                      dateText: Formatters.date(vm.endDate),
                      icon: Icons.event_available_outlined,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blushSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${vm.rentalDays} day${vm.rentalDays > 1 ? 's' : ''} of rental',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.roseDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('Delivery Address',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Where should we bring the item? Saved for your next rental.',
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 12),
              ElegantTextField(
                controller: _addressController,
                hint: 'House #, Street, Barangay, City',
                label: 'ADDRESS',
                prefixIcon: Icons.home_outlined,
                textInputAction: TextInputAction.done,
              ),
              if (savedPlaces.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: savedPlaces.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final place = savedPlaces[index];
                      final selected = _addressController.text.trim() == place;
                      return ActionChip(
                        backgroundColor: selected
                            ? AppColors.blushSoft
                            : Colors.white,
                        side: BorderSide(
                          color: selected
                              ? AppColors.rose
                              : AppColors.champagne,
                        ),
                        avatar: Icon(
                          selected
                              ? Icons.place_rounded
                              : Icons.place_outlined,
                          size: 16,
                          color: selected
                              ? AppColors.roseDark
                              : AppColors.inkSoft,
                        ),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.roseDark
                                  : AppColors.inkSoft,
                            ),
                          ),
                        ),
                        onPressed: () =>
                            setState(() => _addressController.text = place),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 22),
              _PriceBreakdownCard(vm: vm),
              const SizedBox(height: 26),
              GradientButton(
                label: 'Pay & Confirm Rental',
                icon: Icons.verified_user_rounded,
                busy: vm.isConfirming,
                onPressed: _payAndConfirm,
              ),
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded,
                        size: 13, color: AppColors.inkSoft.withValues(alpha: .7)),
                    const SizedBox(width: 6),
                    Text(
                      'Secured payment · Deposit fully refundable',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft.withValues(alpha: .85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final CatalogItem item;

  const _OrderSummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.goldSoft.withValues(alpha: .7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blush.withValues(alpha: .25),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          ItemThumbnail(
            imageUrls: item.thumbnail.isEmpty ? const [] : [item.thumbnail],
            name: item.name,
            width: 74,
            height: 92,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.categoryLabel.toUpperCase()} · ₱${item.basePrice.toStringAsFixed(0)}/day',
                  style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: .4,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft.withValues(alpha: .9),
                  ),
                ),
                const SizedBox(height: 8),
                const StatusBadge(label: 'Reserved for you', color: AppColors.gold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String dateText;
  final IconData icon;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.dateText,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.goldSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: AppColors.rose),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft.withValues(alpha: .8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              dateText,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBreakdownCard extends StatelessWidget {
  final CheckoutViewModel vm;

  const _PriceBreakdownCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.champagne),
        boxShadow: [
          BoxShadow(
            color: AppColors.blush.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Rental Fee (${vm.rentalDays} days)',
              '₱${vm.rentalFee.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _row('Security Deposit', '₱${vm.securityDeposit.toStringAsFixed(0)}',
              note: 'Refundable'),
          const SizedBox(height: 12),
          Divider(color: AppColors.champagne.withValues(alpha: .9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '₱${vm.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {String? note}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
        if (note != null) ...[
          const SizedBox(width: 7),
          StatusBadge(label: note, color: AppColors.success, filled: false),
        ],
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Rental Requested!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Payment received. The shop will review and confirm your rental shortly — track its status anytime under My Rentals.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5, height: 1.55),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'View My Rentals',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}


