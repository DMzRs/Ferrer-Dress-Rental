import 'package:ferrer_rental_shop/core/widgets/top_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _screen = Size(800, 600);

Widget _harness({double navHeight = 0}) {
  return MaterialApp(
    home: Scaffold(
      bottomNavigationBar: navHeight > 0
          ? SizedBox(key: const ValueKey('nav'), height: navHeight)
          : null,
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showAppSnackBar(context, 'Saved.'),
          child: const Text('go'),
        ),
      ),
    ),
  );
}

/// Flush the toast's 4.35s auto-dismiss; pumpAndSettle alone stops early
/// because no frames are scheduled while the delay elapses.
Future<void> _settle(WidgetTester t) async {
  await t.pump(const Duration(seconds: 5));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('toast sits above the bottom nav bar', (t) async {
    await t.pumpWidget(_harness(navHeight: 64));
    await t.tap(find.text('go'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    final toast = t.getRect(find.text('Saved.'));
    final nav = t.getRect(find.byKey(const ValueKey('nav')));
    expect(toast.bottom, lessThanOrEqualTo(nav.top));
    await _settle(t);
  });

  testWidgets('toast sits above the keyboard when up', (t) async {
    // Physical pixels; keep dpr at 1 so logical == physical.
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(800, 600);
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(t.view.reset);
    await t.pumpWidget(_harness());
    await t.tap(find.text('go'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    final toast = t.getRect(find.text('Saved.'));
    expect(toast.bottom, lessThanOrEqualTo(_screen.height - 300));
    await _settle(t);
  });

  testWidgets('no nav bar: toast floats near the bottom edge', (t) async {
    await t.pumpWidget(_harness());
    await t.tap(find.text('go'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    final toast = t.getRect(find.text('Saved.'));
    expect(toast.bottom, greaterThan(_screen.height - 80));
    await _settle(t);
  });
}
