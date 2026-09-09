import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/viewmodels/my_rentals_viewmodel.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/widgets/rental_card.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm = context.watch<MyRentalsViewModel>();

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
                'My Rentals',
                style: TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                '${vm.activeCount} active piece${vm.activeCount == 1 ? '' : 's'} in your wardrobe',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final entry in const {
                    'active': 'Active',
                    'pending': 'Pending',
                    'all': 'All',
                    'completed': 'Completed',
                  }.entries)
                      _FilterChip(
                        label: entry.value,
                        selected: vm.filter == entry.key,
                        onTap: () => vm.setFilter(entry.key),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.rose))
                  : vm.rentals.isEmpty
                      ? EmptyState(
                          icon: Icons.local_mall_outlined,
                          title: 'Nothing here yet',
                          subtitle:
                              'Discover our collection and your rentals will appear here.',
                        )
                      : RefreshIndicator(
                          color: AppColors.roseDark,
                          onRefresh: () async {},
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                            itemCount: vm.rentals.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 14),
                            itemBuilder: (context, index) =>
                                RentalCard(rental: vm.rentals[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: .85),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.goldSoft.withValues(alpha: .8),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

