import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';

/// App-wide top toast. Same role as a SnackBar (lightweight transient
/// feedback) but slides in from the top so it never hides behind the
/// bottom nav bar or keyboard.
///
/// Usage: `showTopSnackBar(context, 'Saved.', backgroundColor: AppColors.success)`
/// instead of `ScaffoldMessenger.of(context).showSnackBar(...)`.
Future<void> showTopSnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = AppColors.ink,
  Duration duration = const Duration(seconds: 4),
}) async {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  final topPadding = MediaQuery.paddingOf(context).top;
  final entry = OverlayEntry(
    builder: (_) => _TopToast(
      message: message,
      backgroundColor: backgroundColor,
      topPadding: topPadding,
      duration: duration,
    ),
  );
  overlay.insert(entry);
  await Future.delayed(duration + const Duration(milliseconds: 350));
  entry.remove();
}

class _TopToast extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final double topPadding;
  final Duration duration;

  const _TopToast({
    required this.message,
    required this.backgroundColor,
    required this.topPadding,
    required this.duration,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  Timer? _dismissTimer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    try {
      await _controller.reverse();
    } on Object {
      // Controller disposed mid-animation (route popped) — nothing to do.
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topPadding + 12,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: _dismiss,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
