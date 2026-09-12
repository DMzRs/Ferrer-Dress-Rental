import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';
import 'package:ferrer_rental_shop/features/booking/domain/repositories/appointment_repository.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

enum ActivityKind { rental, appointment }

class ActivityEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailing;
  final DateTime timestamp;

  /// AdminShell tab to open on tap (1 = Appointments, 3 = Rentals).
  final int tabIndex;

  /// Sub-tab inside the destination screen + the exact record to highlight.
  final ActivityKind kind;
  final int subTab;
  final String recordId;

  const ActivityEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.timestamp,
    required this.tabIndex,
    required this.kind,
    required this.subTab,
    required this.recordId,
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
      for (final r in _rentalList) _rentalEntry(r),
      for (final a in _appointmentList) _appointmentEntry(a),
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

  DateTime _rentalActionTime(Rental r) {
    if (r.isCompleted) return r.returnedAt ?? r.updatedAt ?? r.createdAt;
    return r.updatedAt ?? r.createdAt;
  }

  ActivityEntry _rentalEntry(Rental r) {
    final time = _rentalActionTime(r);
    if (r.isCompleted) {
      return ActivityEntry(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF0D5C50),
        title: r.userName,
        subtitle: 'Marked returned · ${r.itemName}',
        trailing: '₱${r.total.toStringAsFixed(0)}',
        timestamp: time,
        tabIndex: 3,
        kind: ActivityKind.rental,
        subTab: 3,
        recordId: r.id,
      );
    }
    if (r.isDeclined) {
      return ActivityEntry(
        icon: Icons.cancel_rounded,
        color: const Color(0xFFAF3F30),
        title: r.userName,
        subtitle: 'Request declined · ${r.itemName}',
        trailing: '',
        timestamp: time,
        tabIndex: 3,
        kind: ActivityKind.rental,
        subTab: 3,
        recordId: r.id,
      );
    }
    if (r.isCancelled) {
      return ActivityEntry(
        icon: Icons.remove_circle_rounded,
        color: Colors.grey.shade600,
        title: r.userName,
        subtitle: 'Rental cancelled · ${r.itemName}',
        trailing: '',
        timestamp: time,
        tabIndex: 3,
        kind: ActivityKind.rental,
        subTab: 3,
        recordId: r.id,
      );
    }
    return ActivityEntry(
      icon: Icons.local_mall_rounded,
      color: r.isOverdue ? const Color(0xFFAF3F30) : const Color(0xFF0D5C50),
      title: r.userName,
      subtitle: '${r.isPending ? 'New request' : 'Rented'} · ${r.itemName}',
      trailing: '₱${r.total.toStringAsFixed(0)}',
      timestamp: time,
      tabIndex: 3,
      kind: ActivityKind.rental,
      subTab: _rentalSubTab(r),
      recordId: r.id,
    );
  }

  DateTime _appointmentActionTime(Appointment a) =>
      a.updatedAt ?? a.createdAt;

  ActivityEntry _appointmentEntry(Appointment a) {
    final time = _appointmentActionTime(a);
    final resolved = a.status == Appointment.statusDeclined ||
        a.status == Appointment.statusCancelled;
    final confirmed = a.status == Appointment.statusConfirmed ||
        a.status == 'scheduled';
    final action = a.status == Appointment.statusDeclined
        ? 'Declined'
        : a.status == Appointment.statusCancelled
            ? 'Cancelled'
            : confirmed
                ? 'Confirmed'
                : 'New request';
    return ActivityEntry(
      icon: resolved
          ? Icons.event_busy_rounded
          : confirmed
              ? Icons.event_available_rounded
              : Icons.event_note_rounded,
      color: resolved
          ? const Color(0xFFAF3F30)
          : confirmed
              ? const Color(0xFF0D5C50)
              : const Color(0xFFB27A22),
      title: a.userName,
      subtitle: '$action · ${a.purpose} appointment',
      trailing: '',
      timestamp: time,
      tabIndex: 1,
      kind: ActivityKind.appointment,
      subTab: _appointmentSubTab(a),
      recordId: a.id,
    );
  }

  /// RentalTab order: requests(0), active(1), overdue(2), completed(3).
  int _rentalSubTab(Rental r) {
    if (r.isPending) return 0;
    if (r.isOverdue) return 2;
    if (r.isCompleted || r.isCancelled || r.isDeclined) return 3;
    return 1;
  }

  /// Appointment tabs: requests(0), scheduled(1), resolved(2).
  int _appointmentSubTab(Appointment a) {
    if (a.status == Appointment.statusPending) return 0;
    if (a.status == Appointment.statusConfirmed || a.status == 'scheduled') {
      return 1;
    }
    return 2;
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}


