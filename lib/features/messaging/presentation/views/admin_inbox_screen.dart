import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
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

  void _openPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: _CustomerPicker(pageContext: context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            key: const ValueKey('new-message'),
            tooltip: 'New message',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => _openPicker(context),
          ),
        ],
      ),
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
                      onTap: () => openAdminThread(
                        context,
                        conversation.userId,
                        conversation.userName,
                      ),
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

/// Opens a thread screen for [userId], creating nothing until the first
/// message is sent. Shared by inbox rows and the new-message picker.
void openAdminThread(BuildContext context, String userId, String userName) {
  final messages = context.read<MessageRepository>();
  final sender = context.read<SendMessageUseCase>();
  final seen = context.read<MarkSeenUseCase>();
  final auth = context.read<AuthRepository>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AdminThreadScreen(
        userId: userId,
        userName: userName,
        messages: messages,
        sender: sender,
        seen: seen,
        auth: auth,
      ),
    ),
  );
}

/// Customer picker for starting a thread. Lists customer profiles only —
/// messaging is strictly user↔shop.
class _CustomerPicker extends StatefulWidget {
  /// Inbox page context: survives the sheet pop, so the thread push below
  /// never touches a deactivated ancestor.
  final BuildContext pageContext;

  const _CustomerPicker({required this.pageContext});

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New message',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.adminInk,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('customer-search'),
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search customers',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: StreamBuilder<List<AppUser>>(
                stream: context.read<AuthRepository>().watchUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            color: AppColors.adminPrimary),
                      ),
                    );
                  }
                  final customers = (snapshot.data ?? const <AppUser>[])
                      .where((u) =>
                          u.role == UserRole.customer &&
                          (_query.isEmpty ||
                              u.fullName.toLowerCase().contains(_query) ||
                              u.email.toLowerCase().contains(_query)))
                      .toList();
                  if (customers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No customers found.')),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: customers.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = customers[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.adminPrimarySoft,
                          foregroundColor: AppColors.adminPrimary,
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(
                          user.fullName.isEmpty
                              ? user.email
                              : user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          openAdminThread(
                            widget.pageContext,
                            user.uid,
                            user.fullName.isEmpty
                                ? user.email
                                : user.fullName,
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
      ),
    );
  }
}
