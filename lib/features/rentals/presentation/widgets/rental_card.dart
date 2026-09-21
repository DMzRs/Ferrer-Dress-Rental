import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/router/app_router.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/presentation/widgets/rate_pill.dart';

class RentalCard extends StatelessWidget {
  final Rental rental;

  /// Flashes an attention ring (used when jumping from the overdue banner).
  final bool highlight;

  /// Ring color: danger for warnings (overdue), success for fresh arrivals.
  final Color highlightColor;

  /// Item photo(s) resolved from inventory; empty falls back to placeholder.
  final List<String> imageUrls;

  const RentalCard(
      {super.key,
      required this.rental,
      this.highlight = false,
      this.highlightColor = AppColors.danger,
      this.imageUrls = const []});

  Color get _statusColor {
    final (_, color) =
        StatusBadge.resolve(rental.displayStatus, rental.endDate);
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final overdue = rental.displayStatus == 'overdue';

    return GestureDetector(
      onTap: () =>
          context.pushNamed(AppRoutes.rentalDetails, arguments: rental),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: highlight
                ? highlightColor
                : AppColors.champagne.withValues(alpha: .8),
            width: highlight ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: highlight
                  ? highlightColor.withValues(alpha: .35)
                  : AppColors.blush.withValues(alpha: .22),
              blurRadius: highlight ? 22 : 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemThumbnail(
                  imageUrls: imageUrls,
                  name: rental.itemName,
                  width: 66,
                  height: 84,
                  borderRadius: BorderRadius.circular(15),
                  gradientSeed: rental.itemId.hashCode,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              rental.itemName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusBadge(
                            label:
                                StatusBadge.resolve(rental.displayStatus, rental.endDate).$1,
                            color: _statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.date_range_rounded,
                              size: 13.5,
                              color: AppColors.rose.withValues(alpha: .85)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${Formatters.shortDate(rental.startDate)} – ${Formatters.shortDate(rental.endDate)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkSoft.withValues(alpha: .95),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total ₱${rental.total.toStringAsFixed(0)} · Deposit ₱${rental.securityDeposit.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkSoft.withValues(alpha: .8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rental.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.hourglass_top_rounded,
                      size: 14, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Awaiting shop confirmation',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.roseDark.withValues(alpha: .95),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: AppColors.roseDark.withValues(alpha: .7)),
                ],
              ),
            ] else if (rental.status == 'active') ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(height: 7, color: AppColors.champagne.withValues(alpha: .6)),
                    FractionallySizedBox(
                      widthFactor: rental.progress,
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            overdue ? AppColors.danger : AppColors.gold,
                            overdue ? AppColors.adminRed : AppColors.rose,
                          ]),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      overdue
                          ? 'Overdue — please return immediately.'
                          : rental.daysRemaining > 0
                              ? '${rental.daysRemaining} day${rental.daysRemaining == 1 ? '' : 's'} remaining'
                              : 'Due back today',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: overdue ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.roseDark.withValues(alpha: .95),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: AppColors.roseDark.withValues(alpha: .7)),
                    ],
                  ),
                ],
              ),
            ] else if (rental.isCompleted) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RatePill(rental: rental),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.roseDark.withValues(alpha: .95),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: AppColors.roseDark.withValues(alpha: .7)),
                    ],
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.roseDark.withValues(alpha: .95),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: AppColors.roseDark.withValues(alpha: .7)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

