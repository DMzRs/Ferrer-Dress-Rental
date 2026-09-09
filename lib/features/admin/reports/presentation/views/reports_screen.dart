import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/utils/formatters.dart';
import 'package:ferrer_rental_shop/features/admin/reports/presentation/viewmodels/reports_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/reports/presentation/widgets/charts.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportsViewModel>();

    return Scaffold(
      // No appBar on this screen, so keep the revenue card clear of the
      // phone's status bar.
      body: SafeArea(
        bottom: false,
        child: vm.isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppColors.adminPrimary))
            : RefreshIndicator(
                color: AppColors.adminPrimary,
                onRefresh: () async {},
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.adminPrimary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('TOTAL REVENUE',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${vm.completedCount} completed rentals',
                                style: const TextStyle(
                                    fontSize: 10.5, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          Formatters.peso(vm.totalRevenue),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rental fees only · excludes security deposits held',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: .75)),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _miniStat('Deposits Held',
                                Formatters.peso(vm.heldDeposits)),
                            const SizedBox(width: 12),
                            _miniStat(
                                'Active Rentals', '${vm.activeCount}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: 'Revenue by Month',
                    subtitle: 'Last 6 months of rental fees',
                    child: RevenueBarChart(
                      values: vm.points.map((p) => p.revenue).toList(),
                      labels: vm.points.map((p) => p.label).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Rentals Completed per Month',
                    subtitle: 'Items returned on schedule or late',
                    child: RentalsLineChart(
                      values: vm.points
                          .map((p) => p.rentalsCompleted)
                          .toList(),
                      labels: vm.points.map((p) => p.label).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: .7))),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.adminInk)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}


