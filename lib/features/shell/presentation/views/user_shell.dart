import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/viewmodels/my_appointments_viewmodel.dart';
import 'package:ferrer_rental_shop/features/booking/presentation/views/my_appointments_screen.dart';
import 'package:ferrer_rental_shop/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:ferrer_rental_shop/features/home/presentation/views/home_screen.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/viewmodels/my_rentals_viewmodel.dart';
import 'package:ferrer_rental_shop/features/rentals/presentation/views/my_rentals_screen.dart';
import 'profile_screen_tab.dart';

class UserShell extends StatelessWidget {
  const UserShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => HomeViewModel(
            context.read<InventoryRepository>(),
          ),
        ),
        ChangeNotifierProvider<MyRentalsViewModel>(
          create: (_) => MyRentalsViewModel(
            context.read<RentalRepository>(),
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<MyAppointmentsViewModel>(
          create: (_) => MyAppointmentsViewModel(
            context.read<AppointmentRepository>(),
            context.read<AuthRepository>(),
          ),
        ),
      ],
      child: const _UserShellView(),
    );
  }
}

class _UserShellView extends StatefulWidget {
  const _UserShellView();

  @override
  State<_UserShellView> createState() => _UserShellViewState();
}

class _UserShellViewState extends State<_UserShellView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          const MyAppointmentsScreen(),
          const MyRentalsScreen(),
          ProfileScreenTab(
            onNavigateTo: (tab) => setState(() => _index = tab),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .97),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.goldSoft.withValues(alpha: .6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .07),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.blushSoft,
            height: 64,
            labelTextStyle: WidgetStateProperty.all(
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft.withValues(alpha: .9),
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                size: 23,
                color: states.contains(WidgetState.selected)
                    ? AppColors.roseDark
                    : AppColors.inkSoft.withValues(alpha: .65),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note_rounded),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_mall_outlined),
                selectedIcon: Icon(Icons.local_mall_rounded),
                label: 'Rentals',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
