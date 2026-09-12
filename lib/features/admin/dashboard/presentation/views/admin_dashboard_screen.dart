import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/admin/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class AdminDashboardScreen extends StatelessWidget {
  /// Opens an AdminShell tab (e.g. from a Recent Activity tap).
  final void Function(int tabIndex)? onNavigateTo;

  const AdminDashboardScreen({super.key, this.onNavigateTo});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final m = vm.metrics;
    final user = context.watch<AuthViewModel>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ferrer Admin Portal'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded, size: 21),
            onPressed: () => context.read<AuthViewModel>().signOut(),
          ),
        ],
      ),
      body: m.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.adminPrimary))
          : RefreshIndicator(
              color: AppColors.adminPrimary,
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Text(
                    'Welcome back, ${user?.fullName.split(' ').first ?? 'Admin'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      SummaryCard(
                        label: 'Total Sales',
                        value: Formatters.peso(m.totalSales),
                        icon: Icons.payments_rounded,
                        color: AppColors.adminPrimary,
                      ),
                      SummaryCard(
                        label: 'Active Rentals',
                        value: '${m.activeRentals}',
                        icon: Icons.local_mall_rounded,
                        color: AppColors.adminBlue,
                      ),
                      SummaryCard(
                        label: 'Available Inventory',
                        value: '${m.availableInventory}',
                        icon: Icons.checkroom_rounded,
                        color: AppColors.adminAmber,
                      ),
                      SummaryCard(
                        label: 'Total Users',
                        value: '${m.totalUsers}',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.adminRed.withValues(alpha: .85),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Activity',
                          style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.adminInk)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (m.recentActivity.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_empty_rounded,
                                size: 30, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text('No activity yet',
                                style: TextStyle(
                                    fontSize: 13.5, color: AppColors.adminMuted)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...m.recentActivity.map((entry) => ActivityTile(
                          entry: entry,
                          onTap: onNavigateTo == null
                              ? null
                              : () => onNavigateTo!(entry.tabIndex),
                        )),
                ],
              ),
            ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 19.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                  color: AppColors.adminInk,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  final ActivityEntry entry;
  final VoidCallback? onTap;

  const ActivityTile({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: entry.color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(entry.icon, size: 19, color: entry.color),
        ),
        title: Text(
          entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.adminInk),
        ),
        subtitle: Text(
          entry.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        isThreeLine: false,
        dense: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (entry.trailing.isNotEmpty)
                  Text(
                    entry.trailing,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.adminInk),
                  ),
                const SizedBox(height: 3),
                Text(
                  Formatters.timeAgo(entry.timestamp),
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: Colors.grey.shade400),
            ],
          ],
        ),
      ),
    );
  }
}




