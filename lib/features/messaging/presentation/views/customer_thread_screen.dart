import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/viewmodels/thread_viewmodel.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/widgets/thread_view.dart';

class CustomerThreadScreen extends StatelessWidget {
  const CustomerThreadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThreadViewModel>(
      create: (_) => ThreadViewModel(
        messages: context.read<MessageRepository>(),
        sender: context.read<SendMessageUseCase>(),
        seen: context.read<MarkSeenUseCase>(),
        auth: context.read<AuthRepository>(),
      ),
      child: Container(
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
      ),
    );
  }
}
