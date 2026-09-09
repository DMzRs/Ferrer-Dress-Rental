import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';

class RevenueBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const RevenueBarChart({super.key, required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CustomPaint(painter: _BarChartPainter(values: values, labels: labels)),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _BarChartPainter({required this.values, required this.labels});

  static const double bottomPadding = 26;
  static const double topPadding = 24;

  String _compact(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '₱${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
    }
    return '₱${v.toStringAsFixed(0)}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartBottom = size.height - bottomPadding;
    final maxValue = values.reduce(math.max).clamp(1.0, double.infinity);

    final gridPaint = Paint()
      ..color = AppColors.adminBorder.withValues(alpha: .55)
      ..strokeWidth = 1;
    for (final fraction in [.25, .5, .75]) {
      final y = topPadding + (chartBottom - topPadding) * (1 - fraction);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final baselinePaint = Paint()
      ..color = AppColors.adminBorder
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, chartBottom), Offset(size.width, chartBottom), baselinePaint);

    final slotWidth = size.width / values.length;
    final barWidth = math.min(slotWidth * .42, 34.0);

    for (var i = 0; i < values.length; i++) {
      final fraction = values[i] / maxValue;
      final barHeight = (chartBottom - topPadding) * fraction;
      final left = slotWidth * i + (slotWidth - barWidth) / 2;
      final top = chartBottom - math.max(barHeight, 3);

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, top, left + barWidth, chartBottom),
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
      );

      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.adminPrimary,
              AppColors.adminPrimary.withValues(alpha: .5),
            ],
          ).createShader(Rect.fromLTRB(left, top, left + barWidth, chartBottom)),
      );

      if (values[i] > 0) {
        _text(canvas, _compact(values[i]), left + barWidth / 2, top - 15,
            const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.adminMuted));
      }

      _text(canvas, labels[i], slotWidth * i + slotWidth / 2, chartBottom + 8,
          TextStyle(fontSize: 10.5, color: Colors.grey.shade600));
    }
  }

  void _text(Canvas canvas, String text, double x, double y, TextStyle style) {
    final builder = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    builder.paint(canvas, Offset(x - builder.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

class RentalsLineChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;

  const RentalsLineChart({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child:
          CustomPaint(painter: _LineChartPainter(values: values, labels: labels)),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;

  _LineChartPainter({required this.values, required this.labels});

  static const double bottomPadding = 26;
  static const double topPadding = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - bottomPadding;
    final maxVal = values.reduce(math.max).clamp(2, 1 << 30);
    final minVal = values.reduce(math.min).clamp(0, maxVal);
    final range = math.max(1, maxVal - minVal);

    final stepX =
        values.length > 1 ? size.width / (values.length - 1) : size.width;
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          stepX * i,
          topPadding +
              (chartHeight - topPadding) * (1 - (values[i] - minVal) / range),
        ),
    ];

    final gridPaint = Paint()
      ..color = AppColors.adminBorder.withValues(alpha: .6)
      ..strokeWidth = 1;
    for (final y in [topPadding, chartHeight * .5, chartHeight]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = Path();
    if (points.isNotEmpty) linePath.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final mid = Offset((points[i].dx + points[i + 1].dx) / 2,
          (points[i].dy + points[i + 1].dy) / 2);
      linePath.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    if (points.length > 1) linePath.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, chartHeight)
      ..lineTo(points.first.dx, chartHeight)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.adminPrimary.withValues(alpha: .16),
            AppColors.adminPrimary.withValues(alpha: .01),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.adminPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = AppColors.adminPrimary
      ..strokeWidth = 2;

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, dotFill);
      canvas.drawCircle(points[i], 4, dotStroke);

      _text(canvas, '${values[i]}', points[i].dx,
          (points[i].dy - 17).clamp(0.0, size.height),
          const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.adminInk));
      _text(canvas, labels[i], points[i].dx, chartHeight + 8,
          TextStyle(fontSize: 10.5, color: Colors.grey.shade600));
    }
  }

  void _text(Canvas canvas, String text, double x, double y, TextStyle style) {
    final builder = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    builder.paint(canvas, Offset(x - builder.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

