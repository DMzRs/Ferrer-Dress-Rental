import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color color;

  const AppLogo({super.key, this.size = 72, this.color = AppColors.rose});

  @override
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
      child: Icon(
        Icons.local_mall_rounded,
        color: Colors.white,
        size: size * .46,
      ),
    );
  }
}

class FerrerWordmark extends StatelessWidget {
  final Color color;
  final double fontSize;
  final bool showTagline;

  const FerrerWordmark({
    super.key,
    this.color = AppColors.ink,
    this.fontSize = 30,
    this.showTagline = true,
  });

  @override
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

