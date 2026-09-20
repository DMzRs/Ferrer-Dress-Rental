import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/messaging/domain/entities/chat_message.dart';
import 'package:ferrer_rental_shop/features/messaging/presentation/viewmodels/thread_viewmodel.dart';

bool _isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Shared message list + composer. [otherLabel] captions the other side's
/// bubbles ("Ferrer Shop" for customers, customer first name for admins).
/// [emptyText] shows when the thread has no messages yet.
class ThreadView extends StatefulWidget {
  final String otherLabel;
  final String emptyText;

  const ThreadView({
    super.key,
    required this.otherLabel,
    this.emptyText = 'No messages yet. Say hello!',
  });

  @override
  State<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<ThreadView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ThreadViewModel>();
    // Stream yields newest-first; reverse:true pins the newest (index 0)
    // to the bottom. The Load-earlier button is the last builder item,
    // which renders at the top under reverse.
    final messages = vm.messageList;
    final itemCount =
        messages.length + (vm.canLoadEarlier ? 1 : 0);
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    widget.emptyText,
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 14, height: 1.5),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index >= messages.length) {
                      return Center(
                        child: TextButton(
                          onPressed: vm.loadEarlier,
                          child: const Text('Load earlier messages'),
                        ),
                      );
                    }
                    final message = messages[index];
                    final newer = index == 0
                        ? null
                        : messages[index - 1];
                    final showDate = newer == null ||
                        !_isSameDay(
                            newer.createdAt, message.createdAt);
                    return Column(
                      crossAxisAlignment: message.isMine(vm.currentUid ?? '')
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (showDate && message.createdAt != null)
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                Formatters.date(message.createdAt!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        _Bubble(
                          message: message,
                          mine: message.isMine(vm.currentUid ?? ''),
                          otherLabel: widget.otherLabel,
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
        ),
        if (vm.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Text(
              vm.error!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: 1000,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  enabled: !vm.sending,
                  decoration: const InputDecoration(
                    hintText: 'Write a message',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                key: const ValueKey('send-message'),
                icon: const Icon(Icons.send_rounded),
                color: AppColors.roseDark,
                onPressed:
                    vm.sending ? null : () => _send(vm),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _send(ThreadViewModel vm) async {
    final ok = await vm.send(_controller.text);
    if (ok) _controller.clear();
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final String otherLabel;

  const _Bubble({
    required this.message,
    required this.mine,
    required this.otherLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? AppColors.roseDark : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 4),
          bottomRight: Radius.circular(mine ? 4 : 18),
        ),
        border: mine
            ? null
            : Border.all(color: AppColors.champagne),
      ),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                otherLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
          Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: mine ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.createdAt == null
                ? 'Sending…'
                : Formatters.timeAgo(message.createdAt!),
            style: TextStyle(
              fontSize: 10,
              color: (mine ? Colors.white : AppColors.inkSoft)
                  .withValues(alpha: .75),
            ),
          ),
        ],
      ),
    );
  }
}
