import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';

class CategoryPills extends StatelessWidget {
  final Map<String, String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const CategoryPills({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  IconData iconFor(String key) {
    switch (key) {
      case 'dress':
        return Icons.woman_rounded;
      case 'kiddie':
        return Icons.child_care_rounded;
      case 'wedding':
        return Icons.church_rounded;
      case 'party':
        return Icons.celebration_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final key = categories.keys.elementAt(index);
          final label = categories.values.elementAt(index);
          final isSelected = key == selected;
          return GestureDetector(
            onTap: () => onSelect(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.brandGradient : null,
                color: isSelected ? null : Colors.white.withValues(alpha: .85),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.goldSoft.withValues(alpha: .8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.rose.withValues(alpha: .28)
                        : AppColors.blush.withValues(alpha: .16),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconFor(key),
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.rose.withValues(alpha: .85),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final CatalogItem item;
  final int index;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tall = index.isEven;
    final imageHeight = tall ? 190.0 : 150.0;

    return GestureDetector(
      onTap: item.isAvailable ? onTap : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.champagne.withValues(alpha: .7)),
          boxShadow: [
            BoxShadow(
              color: AppColors.blush.withValues(alpha: .25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageArea(imageHeight),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.categoryLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft.withValues(alpha: .75),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '₱${item.basePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                        ),
                      ),
                      Text(
                        ' / day',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkSoft.withValues(alpha: .8),
                        ),
                      ),
                      const Spacer(),
                      if (!item.isAvailable)
                        Icon(
                          item.status == 'maintenance'
                              ? Icons.build_rounded
                              : Icons.event_busy_rounded,
                          size: 15,
                          color: AppColors.danger.withValues(alpha: .7),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppColors.rose,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageArea(double height) {
    final gradients = AppColors.itemPlaceholderGradients;
    final colors = gradients[index % gradients.length];
    return Stack(
      children: [
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(21)),
          child: item.thumbnail.isNotEmpty
              ? SizedBox(
                  height: height,
                  width: double.infinity,
                  child: itemImage(
                    item.thumbnail,
                    errorBuilder: (_, _, _) => _gradientBox(colors, height),
                  ),
                )
              : _gradientBox(colors, height),
        ),
        if (!item.isAvailable)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.shortStatusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                  color: item.status == 'maintenance'
                      ? AppColors.adminAmber
                      : item.status == 'scheduled_for_appointment'
                          ? AppColors.adminPrimary
                          : AppColors.roseDark,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _gradientBox(List<Color> colors, double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Icon(
        Icons.checkroom_rounded,
        size: height * .26,
        color: Colors.white.withValues(alpha: .8),
      ),
    );
  }
}


