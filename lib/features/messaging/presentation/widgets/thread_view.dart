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

  /// Extra clearance below the composer for floating bars (e.g. the user
  /// shell's bottom nav: 64px bar + 14px margin + spacing ≈ 96). Admin
  /// threads sit in their own Scaffold, so this stays 0 there.
  final double bottomPadding;

  /// Shows the "Start conversation" shortcut in the empty state.
  /// Kept only for legacy callers — inside a chat thread the composer
  /// below is already the entry point, so this defaults to hidden.
  final bool showStartButton;

  const ThreadView({
    super.key,
    required this.otherLabel,
    this.emptyText = 'No messages yet. Say hello!',
    this.bottomPadding = 0,
    this.showStartButton = false,
  });

  @override
  State<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<ThreadView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _composerFocus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _composerFocus.dispose();
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.emptyText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 14,
                              height: 1.5),
                        ),
                        if (widget.showStartButton) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _composerFocus.requestFocus(),
                            icon: const Icon(
                                Icons.add_comment_outlined,
                                size: 18),
                            label:
                                const Text('Start conversation'),
                          ),
                        ],
                      ],
                    ),
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
                    // messages is newest-first; index+1 is the next-older
                    // message (visually above). The header belongs above
                    // the OLDEST message of each day, so a new same-day
                    // message below must not drag it down.
                    final older = index + 1 >= messages.length
                        ? null
                        : messages[index + 1];
                    final showDate = older == null ||
                        !_isSameDay(
                            older.createdAt, message.createdAt);
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
        Builder(
          builder: (context) {
            // extendBody:true lets the floating nav sit over the body, so
            // reserve its height when the keyboard is closed. When the
            // keyboard opens the nav is covered and the Scaffold shrinks
            // the body, so drop the reserve to sit flush above keys.
            final keyboardOpen =
                MediaQuery.of(context).viewInsets.bottom > 0;
            final navClearance =
                keyboardOpen ? 0.0 : widget.bottomPadding;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12 + navClearance),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _composerFocus,
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
                    tooltip: 'Send message',
                    onPressed:
                        vm.sending ? null : () => _send(vm),
                  ),
                ],
              ),
            );
          },
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
