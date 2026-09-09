import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

class ActivityEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailing;
  final DateTime timestamp;

  const ActivityEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.timestamp,
  });
}

class DashboardMetrics {
  final double totalSales;
  final int activeRentals;
  final int availableInventory;
  final int totalUsers;
  final List<ActivityEntry> recentActivity;
  final bool isLoading;

  const DashboardMetrics({
    required this.totalSales,
    required this.activeRentals,
    required this.availableInventory,
    required this.totalUsers,
    required this.recentActivity,
    this.isLoading = true,
  });

  static const empty = DashboardMetrics(
    totalSales: 0,
    activeRentals: 0,
    availableInventory: 0,
    totalUsers: 0,
    recentActivity: [],
    isLoading: true,
  );
}

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required RentalRepository rentalRepository,
    required InventoryRepository inventoryRepository,
    required AppointmentRepository appointmentRepository,
    required AuthRepository authRepository,
  })  : _rentals = rentalRepository.allRentalsStream(),
        _items = inventoryRepository.itemsStream(),
        _appointments = appointmentRepository.allAppointmentsStream(),
        _usersCount = authRepository.usersCountStream() {
    _subscriptions.add(_rentals.listen((rentals) {
      _rentalList
        ..clear()
        ..addAll(rentals);
      _recompute();
    }));
    _subscriptions.add(_items.listen((items) {
      _itemList
        ..clear()
        ..addAll(items);
      _recompute();
    }));
    _subscriptions.add(_appointments.listen((appointments) {
      _appointmentList
        ..clear()
        ..addAll(appointments);
      _recompute();
    }));
    _subscriptions.add(_usersCount.listen((count) {
      _userCount = count;
      _recompute();
    }));
  }

  final Stream<List<Rental>> _rentals;
  final Stream<List<CatalogItem>> _items;
  final Stream<List<Appointment>> _appointments;
  final Stream<int> _usersCount;

  final List<StreamSubscription> _subscriptions = [];

  final List<Rental> _rentalList = [];
  final List<CatalogItem> _itemList = [];
  final List<Appointment> _appointmentList = [];
  int _userCount = 0;
  bool _hasData = false;

  DashboardMetrics _metrics = DashboardMetrics.empty;
  DashboardMetrics get metrics => _metrics;

  void _recompute() {
    _hasData = true;
    final sales = _rentalList
        .where((r) => r.status != 'cancelled')
        .fold<double>(0, (sum, r) => sum + r.total);
    final activeCount =
        _rentalList.where((r) => r.status == 'active').length;
    final available = _itemList.where((i) => i.isAvailable).length;

    final activities = <ActivityEntry>[
      for (final r in _rentalList.take(6))
        ActivityEntry(
          icon: Icons.local_mall_rounded,
          color: r.isOverdue ? const Color(0xFFAF3F30) : const Color(0xFF0D5C50),
          title: r.userName,
          subtitle:
              '${r.isCompleted ? 'Returned' : 'Rented'} · ${r.itemName}',
          trailing: '₱${r.total.toStringAsFixed(0)}',
          timestamp: r.createdAt,
        ),
      for (final a in _appointmentList.take(4))
        ActivityEntry(
          icon: Icons.event_available_rounded,
          color: const Color(0xFFB27A22),
          title: a.userName,
          subtitle: '${a.purpose} appointment',
          trailing: '',
          timestamp: a.createdAt,
        ),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _metrics = DashboardMetrics(
      totalSales: sales,
      activeRentals: activeCount,
      availableInventory: available,
      totalUsers: _userCount,
      recentActivity: activities.take(7).toList(),
      isLoading: !_hasData,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}


