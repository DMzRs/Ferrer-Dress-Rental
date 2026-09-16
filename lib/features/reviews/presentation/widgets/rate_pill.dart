import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/entities/review_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:ferrer_rental_shop/features/reviews/presentation/widgets/review_bottom_sheet.dart';

/// Session-scoped set: the gold pulse plays once per unrated rental.
final Set<String> _pulseShown = {};

/// Compact rate/rated pill for completed rental cards.
class RatePill extends StatelessWidget {
  final Rental rental;

  const RatePill({super.key, required this.rental});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Review?>(
      stream:
          context.read<ReviewRepository>().reviewForRentalStream(rental.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PillShell(label: 'Rate', rated: false);
        }
        final review = snapshot.data;
        if (review == null) {
          final firstTime = _pulseShown.add(rental.id);
          final pill = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showReviewSheet(
              context: context,
              rental: rental,
              userId: rental.userId,
            ),
            child: const _PillShell(label: 'Rate', rated: false),
          );
          if (!firstTime) return pill;
          // One-time entrance pulse the first time an unrated pill renders.
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: pill,
          );
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showReviewSheet(
            context: context,
            rental: rental,
            userId: rental.userId,
          ),
          child: _PillShell(
            label: '★ ${review.stars.toDouble().toStringAsFixed(1)}',
            rated: true,
          ),
        );
      },
    );
  }
}

/// Full-width "Your rating" row for the rental details screen.
class YourRatingTile extends StatelessWidget {
  final Rental rental;

  const YourRatingTile({super.key, required this.rental});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Review?>(
      stream:
          context.read<ReviewRepository>().reviewForRentalStream(rental.id),
      builder: (context, snapshot) {
        final review = snapshot.data;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showReviewSheet(
            context: context,
            rental: rental,
            userId: rental.userId,
          ),
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.blushSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.goldSoft),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 18, color: AppColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    review == null
                        ? 'Tap to rate your experience'
                        : '★ ${review.stars.toDouble().toStringAsFixed(1)}'
                            '${review.hasComment ? ' · ${review.comment}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: AppColors.roseDark),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PillShell extends StatelessWidget {
  final String label;
  final bool rated;

  const _PillShell({required this.label, required this.rated});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: rated ? AppColors.gold : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: rated ? AppColors.gold : AppColors.gold.withValues(alpha: .8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rated ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: rated ? Colors.white : AppColors.gold,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: rated ? Colors.white : AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
