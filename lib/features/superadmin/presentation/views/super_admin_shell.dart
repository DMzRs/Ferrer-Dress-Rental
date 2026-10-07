import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/theme/app_theme.dart';
import 'package:ferrer_rental_shop/features/admin/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/reports/presentation/viewmodels/reports_viewmodel.dart';
import 'package:ferrer_rental_shop/features/audit/domain/audit_logger.dart';
import 'package:ferrer_rental_shop/features/audit/domain/repositories/audit_repository.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/viewmodels/accounts_viewmodel.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/viewmodels/audit_log_viewmodel.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/views/accounts_screen.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/views/logs_screen.dart';
import 'package:ferrer_rental_shop/features/superadmin/presentation/views/metrics_screen.dart';

class SuperAdminShell extends StatelessWidget {
  const SuperAdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AccountsViewModel>(
          create: (_) => AccountsViewModel(
            auth: context.read<AuthRepository>(),
            audit: context.read<AuditLogger>(),
            rentals: context.read<RentalRepository>(),
          ),
        ),
        ChangeNotifierProvider<DashboardViewModel>(
          create: (_) => DashboardViewModel(
            rentalRepository: context.read<RentalRepository>(),
            inventoryRepository: context.read<InventoryRepository>(),
            appointmentRepository: context.read<AppointmentRepository>(),
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<ReportsViewModel>(
          create: (_) =>
              ReportsViewModel(context.read<RentalRepository>()),
        ),
        ChangeNotifierProvider<AuditLogViewModel>(
          create: (_) =>
              AuditLogViewModel(context.read<AuditRepository>()),
        ),
      ],
      child: Theme(
        data: AppTheme.admin,
        child: const _SuperAdminShellView(),
      ),
    );
  }
}

class _SuperAdminShellView extends StatefulWidget {
  const _SuperAdminShellView();

  @override
  State<_SuperAdminShellView> createState() => _SuperAdminShellViewState();
}

class _SuperAdminShellViewState extends State<_SuperAdminShellView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Large system fonts would overlap the labels, so fall back to
    // icons only (labels remain as tooltips/semantics).
    final hideLabels =
        MediaQuery.textScalerOf(context).scale(1) > 1.2;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            AccountsScreen(),
            MetricsScreen(),
            LogsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          labelBehavior: hideLabels
              ? NavigationDestinationLabelBehavior.alwaysHide
              : NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Accounts',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Metrics',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Logs',
            ),
          ],
        ),
      ),
    );
  }
}
