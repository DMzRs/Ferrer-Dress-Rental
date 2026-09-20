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
      child: const SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
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
              Expanded(
                child: ThreadView(otherLabel: 'Ferrer Shop'),
              ),
            ],
          ),
        ),
      );
  }
}
