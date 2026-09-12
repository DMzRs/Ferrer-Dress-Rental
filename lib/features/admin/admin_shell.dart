import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/theme/app_theme.dart';
import 'package:ferrer_rental_shop/features/admin/appointments/presentation/viewmodels/appointments_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/appointments/presentation/views/admin_appointments_screen.dart';
import 'package:ferrer_rental_shop/features/admin/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/dashboard/presentation/views/admin_dashboard_screen.dart';
import 'package:ferrer_rental_shop/features/admin/inventory/presentation/viewmodels/inventory_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/inventory/presentation/views/inventory_management_screen.dart';
import 'package:ferrer_rental_shop/features/admin/rental_management/presentation/viewmodels/rental_management_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/rental_management/presentation/views/rental_management_screen.dart';
import 'package:ferrer_rental_shop/features/admin/reports/presentation/viewmodels/reports_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/reports/presentation/views/reports_screen.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/confirm_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/decline_rental_usecase.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/usecases/process_return_usecase.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DashboardViewModel>(
          create: (_) => DashboardViewModel(
            rentalRepository: context.read<RentalRepository>(),
            inventoryRepository: context.read<InventoryRepository>(),
            appointmentRepository: context.read<AppointmentRepository>(),
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<AppointmentsViewModel>(
          create: (_) => AppointmentsViewModel(
            context.read<AppointmentRepository>(),
            context.read<InventoryRepository>(),
          ),
        ),
        ChangeNotifierProvider<InventoryViewModel>(
          create: (_) => InventoryViewModel(context.read<InventoryRepository>()),
        ),
        ChangeNotifierProvider<RentalManagementViewModel>(
          create: (_) => RentalManagementViewModel(
            context.read<RentalRepository>(),
            context.read<ProcessReturnUseCase>(),
            context.read<ConfirmRentalUseCase>(),
            context.read<DeclineRentalUseCase>(),
          ),
        ),
        ChangeNotifierProvider<ReportsViewModel>(
          create: (_) => ReportsViewModel(context.read<RentalRepository>()),
        ),
      ],
      child: Theme(
        data: AppTheme.admin,
        child: const _AdminShellView(),
      ),
    );
  }
}

class _AdminShellView extends StatefulWidget {
  const _AdminShellView();

  @override
  State<_AdminShellView> createState() => _AdminShellViewState();
}

class _AdminShellViewState extends State<_AdminShellView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            AdminDashboardScreen(
              onNavigateTo: (tab) => setState(() => _index = tab),
            ),
            const AdminAppointmentsScreen(),
            const InventoryManagementScreen(),
            const RentalManagementScreen(),
            const ReportsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note_rounded),
              label: 'Appointments',
            ),
            NavigationDestination(
              icon: Icon(Icons.checkroom_outlined),
              selectedIcon: Icon(Icons.checkroom_rounded),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Rentals',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}


