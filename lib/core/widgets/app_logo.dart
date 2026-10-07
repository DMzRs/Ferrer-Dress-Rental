import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';

/// Circular branded app logo.
class AppLogo extends StatelessWidget {
  /// Logo diameter in logical pixels.
  final double size;

  const AppLogo({super.key, this.size = 72});

  @override
  /// Builds the circular logo image.
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.blush.withValues(alpha: .55),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Ferrer brand wordmark with tagline.
class FerrerWordmark extends StatelessWidget {
  /// Text color for the wordmark.
  final Color color;
  /// Base font size for the brand name.
  final double fontSize;
  /// Whether to show the tagline row.
  final bool showTagline;

  const FerrerWordmark({
    super.key,
    this.color = AppColors.ink,
    this.fontSize = 30,
    this.showTagline = true,
  });

  @override
  /// Builds the wordmark and tagline.
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Ferrer',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: fontSize,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _line(),
              const SizedBox(width: 8),
              Text(
                'CLOTHING RENTAL',
                style: TextStyle(
                  fontSize: fontSize * .3,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: .65),
                ),
              ),
              const SizedBox(width: 8),
              _line(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _line() => Container(
        width: 26,
        height: 1,
        color: color.withValues(alpha: .45),
      );
}

