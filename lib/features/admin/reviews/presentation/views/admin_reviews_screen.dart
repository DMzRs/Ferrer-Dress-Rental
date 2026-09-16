import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/admin/reviews/presentation/viewmodels/admin_reviews_viewmodel.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';

class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminReviewsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Reviews')),
      body: StreamBuilder<List<Review>>(
        stream: vm.allReviews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.adminPrimary,
              ),
            );
          }
          final all = snapshot.data ?? [];
          final shown = vm.applyFilter(all);
          if (all.isEmpty) {
            return const Center(child: Text('No reviews yet'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                count: all.length,
                avg: AdminReviewsViewModel.average(all),
              ),
              const SizedBox(height: 12),
              _FilterRow(
                selected: vm.filter,
                onSelect: vm.setFilter,
              ),
              const SizedBox(height: 12),
              if (shown.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text('Nothing in this filter'),
                  ),
                )
              else
                for (final review in shown) ...[
                  _ReviewTile(review: review),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int count;
  final double avg;

  const _SummaryCard({required this.count, required this.avg});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.star_rounded,
                size: 26, color: AppColors.adminAmber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '★ ${avg.toStringAsFixed(1)} ($count)',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adminInk,
                ),
              ),
            ),
            const Text(
              'all time',
              style: TextStyle(fontSize: 12, color: AppColors.adminMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _FilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = {0: 'All', 5: '5', 4: '4', 3: '3', 2: '2', 1: '1'};
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in options.entries)
          ChoiceChip(
            label: entry.key == 0
                ? Text(entry.value)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.adminAmber,
                      ),
                      const SizedBox(width: 2),
                      Text(entry.value),
                    ],
                  ),
            selected: selected == entry.key,
            onSelected: (_) => onSelect(entry.key),
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final firstName =
        review.userName.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.itemName.isEmpty ? 'Rental' : review.itemName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.adminInk,
                    ),
                  ),
                ),
                Text(
                  '★ ${review.stars.toDouble().toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.adminAmber,
                  ),
                ),
              ],
            ),
            if (review.hasComment) ...[
              const SizedBox(height: 6),
              Text(
                review.comment,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.adminInk,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${firstName.isEmpty ? 'A customer' : firstName} · ${Formatters.date(review.createdAt)}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.adminMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
