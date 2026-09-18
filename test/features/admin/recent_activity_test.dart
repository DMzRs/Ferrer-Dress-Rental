import 'package:ferrer_rental_shop/features/admin/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:ferrer_rental_shop/features/admin/dashboard/presentation/views/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<ActivityEntry> _entries(int n) => List.generate(
      n,
      (i) => ActivityEntry(
        icon: Icons.local_mall_rounded,
        color: Colors.teal,
        title: 'Activity $i',
        subtitle: 'detail $i',
        trailing: '',
        timestamp: DateTime(2026, 9, 10 - i),
        tabIndex: 3,
        kind: ActivityKind.rental,
        subTab: 0,
        recordId: 'r$i',
      ),
    );

void main() {
  testWidgets('shows first 5 with View all, expands to rest', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecentActivitySection(entries: _entries(8), onNavigateTo: (_) {}),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Activity 0'), findsOneWidget);
    expect(find.text('Activity 4'), findsOneWidget);
    expect(find.text('Activity 5'), findsNothing);
    await t.tap(find.text('View all'));
    await t.pumpAndSettle();
    expect(find.text('Activity 7'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
    await t.tap(find.text('Show less'));
    await t.pumpAndSettle();
    expect(find.text('Activity 5'), findsNothing);
  });

  testWidgets('no View all button when 5 or fewer', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecentActivitySection(entries: _entries(3), onNavigateTo: (_) {}),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('View all'), findsNothing);
    expect(find.text('Show less'), findsNothing);
    expect(find.text('Activity 2'), findsOneWidget);
  });
}
