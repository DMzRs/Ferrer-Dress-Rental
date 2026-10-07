import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/audit/domain/action_label.dart';
import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/viewmodels/audit_log_viewmodel.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuditLogViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded, size: 21),
            onPressed: () => context.read<AuthViewModel>().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final filter in LogFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: vm.filter == filter,
                      onSelected: (_) => vm.setFilter(filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: StreamBuilder<List<AuditLogEntry>>(
              stream: vm.entries,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.adminPrimary),
                  );
                }
                // A denied read (e.g. outdated Firestore rules) surfaces
                // here, not as an empty feed.
                if (snapshot.hasError) {
                  return const EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Couldn\'t load logs',
                    subtitle:
                        'Check your connection and Firestore rules, then try again.',
                  );
                }
                final entries = snapshot.data ?? const <AuditLogEntry>[];
                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No activity yet',
                    subtitle:
                        'Account, rental, appointment, and inventory actions will appear here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _LogTile(entry: entries[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AuditLogEntry entry;

  const _LogTile({required this.entry});

  /// Backfilled entries are acted by the importer, so name the subject
  /// from `meta` instead of showing the importer everywhere.
  String get _subject {
    final metaEmail = (entry.meta['email'] ?? '').trim();
    return metaEmail.isNotEmpty ? metaEmail : entry.actorEmail;
  }

  bool get _imported => entry.meta['backfilled'] == 'true';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.adminPrimarySoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.history_rounded,
              size: 20, color: AppColors.adminPrimary),
        ),
        title: Text(
          entry.action.actionLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.adminInk),
        ),
        subtitle: Text(
          '$_subject'
          '${entry.targetId.isNotEmpty ? ' · ${entry.targetId}' : ''}'
          '${_imported ? ' · imported' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          Formatters.timeAgo(entry.at),
          style: const TextStyle(
              fontSize: 10.5, color: AppColors.adminMuted),
        ),
      ),
    );
  }
}
