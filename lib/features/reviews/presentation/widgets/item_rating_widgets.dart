import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';

/// `★ 4.5 (12)` header line, or an empty-state hint.
class ItemRatingHeader extends StatelessWidget {
  final String itemId;

  const ItemRatingHeader({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RatingSummary>(
      stream:
          context.read<ReviewRepository>().ratingSummaryStream(itemId),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        if (summary == null || summary.count == 0) {
          return const Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          );
        }
        return Text(
          '★ ${summary.avg.toStringAsFixed(1)} (${summary.count})',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
          ),
        );
      },
    );
  }
}

/// Latest reviews for an item, newest first (max 5).
class ItemReviewList extends StatelessWidget {
  final String itemId;

  const ItemReviewList({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: context.read<ReviewRepository>().itemReviewsStream(itemId),
      builder: (context, snapshot) {
        final reviews = (snapshot.data ?? []).take(5).toList();
        if (reviews.isEmpty) {
          return const Text(
            'Be the first to review this piece after your rental.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          );
        }
        return Column(
          children: [
            for (final review in reviews) ...[
              _ReviewRow(review: review),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final Review review;

  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    final firstName = review.userName.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.champagne.withValues(alpha: .8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  firstName.isEmpty ? 'A customer' : firstName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '★ ${review.stars.toDouble().toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.date(review.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
              ),
            ],
          ),
          if (review.hasComment) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
