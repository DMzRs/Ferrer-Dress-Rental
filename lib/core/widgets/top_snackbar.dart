import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';

/// App-wide bottom toast. Same role as a SnackBar (lightweight transient
/// feedback) but floats above the bottom nav bar so it is never hidden
/// behind it. When the keyboard is up it floats just above the keyboard
/// instead.
///
/// Usage: `showAppSnackBar(context, 'Saved.', backgroundColor: AppColors.success)`
/// instead of `ScaffoldMessenger.of(context).showSnackBar(...)`.
Future<void> showAppSnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = AppColors.ink,
  Duration duration = const Duration(seconds: 4),
}) async {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  // The nav bar lives in the caller's Scaffold (body context can see it).
  final hasNavBar =
      Scaffold.maybeOf(context)?.widget.bottomNavigationBar != null;

  final entry = OverlayEntry(
    builder: (overlayContext) {
      // Keyboard insets must come from ABOVE the Scaffold: Scaffold consumes
      // viewInsets for its body (resizeToAvoidBottomInset), so the caller's
      // context always reports zero while the keyboard is up.
      final media = MediaQuery.of(overlayContext);
      final keyboard = media.viewInsets.bottom;
      // Clearance for the floating nav bars (user ~78px, admin ~68px).
      // Nav-less screens (login, details) only need the edge gap.
      final bottom = keyboard > 0
          ? keyboard + 12
          : media.padding.bottom + (hasNavBar ? 80 : 4) + 12;
      return _BottomToast(
        message: message,
        backgroundColor: backgroundColor,
        bottomPadding: bottom,
        duration: duration,
      );
    },
  );
  overlay.insert(entry);
  await Future.delayed(duration + const Duration(milliseconds: 350));
  entry.remove();
}

class _BottomToast extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final double bottomPadding;
  final Duration duration;

  const _BottomToast({
    required this.message,
    required this.backgroundColor,
    required this.bottomPadding,
    required this.duration,
  });

  @override
  State<_BottomToast> createState() => _BottomToastState();
}

class _BottomToastState extends State<_BottomToast>
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
      begin: const Offset(0, 1.2),
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
      bottom: widget.bottomPadding,
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
