import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/viewmodels/thread_viewmodel.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/widgets/thread_view.dart';

class AdminThreadScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final MessageRepository messages;
  final SendMessageUseCase sender;
  final MarkSeenUseCase seen;
  final AuthRepository auth;

  const AdminThreadScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.messages,
    required this.sender,
    required this.seen,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThreadViewModel>(
      create: (_) => ThreadViewModel(
        messages: messages,
        sender: sender,
        seen: seen,
        auth: auth,
        autoMarkRead: true,
      )..openThread(userId),
      child: Scaffold(
        appBar: AppBar(
          title: Text(userName.isEmpty ? 'Customer' : userName),
        ),
        body: ThreadView(otherLabel: _firstName(userName)),
      ),
    );
  }

  static String _firstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'Customer';
    return parts.first;
  }
}
