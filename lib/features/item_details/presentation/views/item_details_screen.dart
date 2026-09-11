import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/widgets/top_snackbar.dart';
import 'package:ferrer_rental_shop/core/constants/app_strings.dart';
import 'package:ferrer_rental_shop/core/router/app_router.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/views/booking_screen.dart';
import 'package:ferrer_rental_shop/features/item_details/presentation/viewmodels/item_details_viewmodel.dart';

class ItemDetailsScreen extends StatelessWidget {
  final CatalogItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ItemDetailsViewModel(
        item,
        context.read<InventoryRepository>(),
      ),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemDetailsViewModel>();
    final item = vm.item;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Carousel(vm: vm)),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.cream,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(height: 1.25),
                              ),
                            ),
                            _CategoryChip(label: item.categoryLabel),
                          ],
                        ),
                        if (!item.isAvailable) ...[
                          const SizedBox(height: 10),
                          StatusBadge(
                            label: item.statusLabel,
                            color: item.status == 'maintenance'
                                ? AppColors.adminAmber
                                : item.status == 'scheduled_for_appointment'
                                    ? AppColors.adminPrimary
                                    : AppColors.roseDark,
                          ),
                        ],
                        if (item.occasions.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final occasion in item.occasions)
                                _OccasionTag(occasion: occasion),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₱${item.basePrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                              ),
                              TextSpan(
                                text: '  / day',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.inkSoft.withValues(alpha: .9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _DepositInfoBox(amount: item.securityDeposit),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('About this piece',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.inkSoft, height: 1.55),
                          ),
                        ],
                        if (item.sizes.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Available Sizes',
                                  style: Theme.of(context).textTheme.titleLarge),
                              if (!vm.canRent)
                                const Text(
                                  'Select a size first',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final size in item.sizes)
                                _SizeChip(
                                  label: size,
                                  selected: vm.selectedSize == size,
                                  onTap: () => vm.selectSize(size),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          _BottomBar(vm: vm),
        ],
      ),
    );
  }
}

class _Carousel extends StatelessWidget {
  final ItemDetailsViewModel vm;

  const _Carousel({required this.vm});

  @override
  Widget build(BuildContext context) {
    final images = vm.photos;
    final pageCount = images.isEmpty ? 3 : images.length;
    final gradients = AppColors.itemPlaceholderGradients;

    return SizedBox(
      height: 380,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: pageCount,
            onPageChanged: vm.setPage,
            itemBuilder: (context, index) {
              if (images.isEmpty) {
                final colors = gradients[index % gradients.length];
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                  child: Icon(
                    Icons.checkroom_rounded,
                    size: 110,
                    color: Colors.white.withValues(alpha: .75),
                  ),
                );
              }
              return itemImage(images[index], fit: BoxFit.cover);
            },
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .25, .8, 1],
                  colors: [
                    Colors.black38,
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x66FDF8F2),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleAction(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _CircleAction(
                  icon: Icons.favorite_border_rounded,
                  onTap: () {},
                ),
              ],
            ),
          ),
          if (pageCount > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pageCount, (index) {
                  final active = index == vm.currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 17, color: AppColors.ink),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blushSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.blush),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: .5,
          color: AppColors.roseDark,
        ),
      ),
    );
  }
}

class _OccasionTag extends StatelessWidget {
  final String occasion;

  const _OccasionTag({required this.occasion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.champagne.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        occasion[0].toUpperCase() + occasion.substring(1),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.inkSoft,
        ),
      ),
    );
  }
}

class _DepositInfoBox extends StatelessWidget {
  final double amount;

  const _DepositInfoBox({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.champagne.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.goldSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_rounded,
                size: 19, color: AppColors.gold),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: AppStrings.depositInfoTitle),
                    TextSpan(
                      text: '  ·  ₱${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ]),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppStrings.depositInfoBody,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.inkSoft.withValues(alpha: .95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SizeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.goldSoft,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.rose.withValues(alpha: .3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final ItemDetailsViewModel vm;

  const _BottomBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).padding.bottom + 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .97),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border:
              Border.all(color: AppColors.champagne.withValues(alpha: .8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.blush.withValues(alpha: .3),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.pushNamed(
                  AppRoutes.booking,
                  arguments: BookingScreenArgs(
                    itemId: vm.item.id,
                    itemName: vm.item.name,
                  ),
                ),
                icon: const Icon(Icons.event_available_rounded, size: 18),
                label: const Text('Book a Fitting'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: GradientButton(
                label: 'Rent Now',
                height: 52,
                onPressed: vm.canRent && vm.item.isAvailable
                    ? () => context.pushNamed(AppRoutes.checkout,
                        arguments: vm.item)
                    : () {
                        showTopSnackBar(
                          context,
                          !vm.item.isAvailable
                              ? 'This piece is currently ${vm.item.statusLabel.toLowerCase()}.'
                              : 'Please select your size to continue.',
                          backgroundColor: AppColors.danger,
                        );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

