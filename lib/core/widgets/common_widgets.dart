import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';

/// Renders an item photo from either a data URI (photos stored in
/// Firestore on the free plan) or an http(s) URL (external hosting).
Widget itemImage(
  String src, {
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  final onError = errorBuilder;
  if (src.startsWith('data:')) {
    return Image.memory(
      base64Decode(src.split(',').last),
      fit: fit,
      errorBuilder: onError,
    );
  }
  return Image.network(src, fit: fit, errorBuilder: onError);
}

class ElegantTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const ElegantTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 14.5, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.rose.withValues(alpha: .8))
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, size: 20, color: AppColors.inkSoft),
                    onPressed: onSuffixTap,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Gradient? gradient;
  final double height;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.gradient = AppColors.brandGradientStrong,
    this.height = 54,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final contentColor = enabled ? Colors.white : AppColors.inkSoft;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled ? null : AppColors.champagne,
        borderRadius: BorderRadius.circular(height / 2.8),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.rose.withValues(alpha: .35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          minimumSize: Size.fromHeight(height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(height / 2.8)),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: contentColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                      color: busy ? Colors.white : contentColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

enum RentalStatusType { active, overdue, completed, upcoming, cancelled, scheduled }

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.filled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  static (String, Color) resolve(String status, DateTime? endDate) {
    switch (status) {
      case 'completed':
        return ('Completed', AppColors.adminMuted);
      case 'cancelled':
        return ('Cancelled', AppColors.adminRed);
      case 'declined':
        return ('Declined', AppColors.danger);
      case 'pending':
        return ('Pending', AppColors.gold);
      case 'overdue':
        return ('Overdue', AppColors.danger);
      case 'scheduled':
        return ('Scheduled', AppColors.adminBlue);
    }
    if (endDate != null && Formatters.daysBetween(DateTime.now(), endDate) < 0) {
      return ('Overdue', AppColors.danger);
    }
    return ('Active', AppColors.success);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: .14) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
          color: filled ? color : color,
        ),
      ),
    );
  }
}

class ItemThumbnail extends StatelessWidget {
  final List<String> imageUrls;
  final String name;
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final int gradientSeed;

  const ItemThumbnail({
    super.key,
    required this.imageUrls,
    required this.name,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.gradientSeed = 0,
  });

  @override
  Widget build(BuildContext context) {
    final gradients = AppColors.itemPlaceholderGradients;
    final colors = gradients[gradientSeed % gradients.length];
    final hasImage = imageUrls.isNotEmpty;

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: hasImage && imageUrls.first.isNotEmpty
            ? itemImage(
                imageUrls.first,
                errorBuilder: (_, _, _) => _placeholder(colors),
              )
            : _placeholder(colors),
      ),
    );
  }

  Widget _placeholder(List<Color> colors) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors)),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: height * .32,
          color: Colors.white.withValues(alpha: .85),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.blushSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.rose.withValues(alpha: .8)),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

