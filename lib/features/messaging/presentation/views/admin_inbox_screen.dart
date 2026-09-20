import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/conversation.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/mark_seen_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/views/admin_thread_screen.dart';

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              key: const ValueKey('inbox-search'),
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search customers',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Conversation>>(
              stream: context
                  .read<MessageRepository>()
                  .watchInbox(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.adminPrimary),
                  );
                }
                final threads = (snapshot.data ?? const [])
                    .where((c) => _query.isEmpty ||
                        c.userName.toLowerCase().contains(_query))
                    .toList();
                if (threads.isEmpty) {
                  return const Center(
                    child: Text(
                      'No conversations yet.',
                      style: TextStyle(
                          color: AppColors.adminMuted, fontSize: 14),
                    ),
                  );
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: threads.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final conversation = threads[index];
                    return _InboxRow(
                      conversation: conversation,
                      onTap: () {
                        final messages =
                            context.read<MessageRepository>();
                        final sender =
                            context.read<SendMessageUseCase>();
                        final seen =
                            context.read<MarkSeenUseCase>();
                        final auth =
                            context.read<AuthRepository>();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminThreadScreen(
                              userId: conversation.userId,
                              userName: conversation.userName,
                              messages: messages,
                              sender: sender,
                              seen: seen,
                              auth: auth,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _InboxRow({required this.conversation, required this.onTap});

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.adminPrimarySoft,
          foregroundColor: AppColors.adminPrimary,
          child: Text(
            _initials(conversation.userName),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          conversation.userName.isEmpty
              ? 'Customer'
              : conversation.userName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.adminInk),
        ),
        subtitle: Text(
          conversation.lastText.isEmpty
              ? 'No messages yet.'
              : conversation.lastText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.unreadForAdmin)
              Container(
                key: ValueKey('unread-${conversation.userId}'),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.adminRed,
                  shape: BoxShape.circle,
                ),
              ),
            if (conversation.updatedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                Formatters.timeAgo(conversation.updatedAt!),
                style: const TextStyle(
                    fontSize: 10.5, color: AppColors.adminMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
