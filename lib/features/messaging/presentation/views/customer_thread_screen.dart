import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/viewmodels/thread_viewmodel.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/widgets/thread_view.dart';

/// Customer chat tab. The [ThreadViewModel] is provided by [UserShell] (one
/// instance shared with the nav badge); this screen only watches it.
class CustomerThreadScreen extends StatelessWidget {
  const CustomerThreadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribed by UserShell; watching here rebuilds on new messages.
    context.watch<ThreadViewModel>();
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.creamGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(
                  'Messages',
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Semantics(
                  label:
                      'Your message will be directed to the shop owner immediately',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.champagne),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.storefront_outlined,
                            size: 18,
                            color: AppColors.roseDark,
                            semanticLabel: 'Shop owner',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Direct line to the shop owner',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your message will be directed to the owner immediately.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: ThreadView(
                  otherLabel: 'Ferrer Shop',
                  // Floating nav (64px + 14px margin) sits over the body
                  // via extendBody:true — keep the composer above it.
                  bottomPadding: 96,
                  // User side types directly in the composer.
                  showStartButton: false,
                ),
              ),
            ],
          ),
        ),
      );
  }
}
