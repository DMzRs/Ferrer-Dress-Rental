/// Distributes grid items across columns for the Discover masonry layout.
///
/// Returns one display index per slot, grouped by column. The display index
/// drives [ItemCard]'s alternating tall/short image heights, so it is phased
/// by column (`column + position-in-column`): each column alternates
/// tall/short starting on the opposite phase from its neighbor, keeping
/// column heights balanced. A plain round-robin item index would put every
/// tall card in the left column.
List<List<int>> distributeIntoColumns(int itemCount, int crossAxisCount) {
  final columns = List.generate(crossAxisCount, (_) => <int>[]);
  for (var i = 0; i < itemCount; i++) {
    final column = i % crossAxisCount;
    columns[column].add(column + columns[column].length);
  }
  return columns;
}
