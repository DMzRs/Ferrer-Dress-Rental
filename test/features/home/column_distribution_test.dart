import 'package:ferrer_rental_shop/features/home/presentation/utils/column_distribution.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors ItemCard's rule: even display index = tall image.
bool _tall(int displayIndex) => displayIndex.isEven;

void main() {
  test('round-robin counts differ by at most one', () {
    final columns = distributeIntoColumns(5, 2);
    expect(columns.length, 2);
    expect(columns[0].length, 3);
    expect(columns[1].length, 2);
  });

  test('tall cards alternate within each column on opposite phases', () {
    final columns = distributeIntoColumns(6, 2);
    // Left: tall, short, tall. Right: short, tall, short.
    expect(columns[0].map(_tall).toList(), [true, false, true]);
    expect(columns[1].map(_tall).toList(), [false, true, false]);
  });

  test('tall counts stay balanced for odd totals', () {
    final columns = distributeIntoColumns(5, 2);
    final tallCounts = columns
        .map((col) => col.where(_tall).length)
        .toList();
    expect(tallCounts, [2, 1]);
  });

  test('works for wide layouts and edge cases', () {
    final wide = distributeIntoColumns(7, 4);
    expect(wide.map((c) => c.length).toList(), [2, 2, 2, 1]);
    // Each column alternates starting phase by column.
    expect(wide[2].map(_tall).toList(), [true, false]);
    expect(wide[3].map(_tall).toList(), [false]);
    expect(distributeIntoColumns(0, 2), [[], []]);
    expect(distributeIntoColumns(1, 2).map((c) => c.length).toList(), [1, 0]);
  });
}
