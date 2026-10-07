import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/admin/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/dashboard/presentation/views/admin_dashboard_screen.dart';
import 'package:ferrer_rental_shop/features/admin/reports/presentation/viewmodels/reports_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/reports/presentation/widgets/charts.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';

/// Read-only business metrics for the superadmin: summary cards plus the
/// revenue charts, reusing the admin dashboard/reports viewmodels.
class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metrics'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded, size: 21),
            onPressed: () => context.read<AuthViewModel>().signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: const [
          _SummaryGrid(),
          SizedBox(height: 14),
          _RevenueSection(),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    final m = context.watch<DashboardViewModel>().metrics;
    if (m.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child:
              CircularProgressIndicator(color: AppColors.adminPrimary),
        ),
      );
    }
    return GridView.count(
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
          icon: Icons.assignment_rounded,
          color: AppColors.adminAmber,
        ),
        SummaryCard(
          label: 'Available Items',
          value: '${m.availableInventory}',
          icon: Icons.checkroom_rounded,
          color: AppColors.adminViolet,
        ),
        SummaryCard(
          label: 'Total Users',
          value: '${m.totalUsers}',
          icon: Icons.people_rounded,
          color: AppColors.adminBlue,
        ),
      ],
    );
  }
}

class _RevenueSection extends StatelessWidget {
  const _RevenueSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportsViewModel>();
    if (vm.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child:
              CircularProgressIndicator(color: AppColors.adminPrimary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MoneyBox(
                label: 'TOTAL REVENUE',
                value: Formatters.peso(vm.totalRevenue),
                footnote:
                    '${vm.completedCount} completed · ${Formatters.peso(vm.heldDeposits)} deposits held',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MoneyBox(
                label: 'DEVELOPER SHARE · 5%',
                value: Formatters.peso(vm.totalDeveloperCut),
                footnote: 'Platform cut on rental fees',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in const {
              ReportPeriod.daily: 'Daily',
              ReportPeriod.weekly: 'Weekly',
              ReportPeriod.monthly: 'Monthly',
            }.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: vm.period == entry.key,
                onSelected: (_) => vm.setPeriod(entry.key),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Revenue',
          child: RevenueBarChart(
            values: vm.points.map((p) => p.revenue).toList(),
            labels: vm.points.map((p) => p.label).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Rentals completed',
          child: RentalsLineChart(
            values:
                vm.points.map((p) => p.rentalsCompleted).toList(),
            labels: vm.points.map((p) => p.label).toList(),
          ),
        ),
      ],
    );
  }
}

class _MoneyBox extends StatelessWidget {
  final String label;
  final String value;
  final String footnote;

  const _MoneyBox({
    required this.label,
    required this.value,
    required this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.adminPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Colors.white70),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            footnote,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.adminInk),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
