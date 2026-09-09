import 'dart:async';

import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';
import 'package:ferrer_rental_shop/features/inventory/data/models/catalog_item_model.dart';
import 'item_data_source.dart';

class MockItemDataSource implements ItemDataSource {
  MockItemDataSource() {
    _items = _seed();
  }

  late final List<CatalogItem> _items;
  final StreamController<List<CatalogItem>> _controller =
      StreamController<List<CatalogItem>>.broadcast();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_items));
    }
  }

  @override
  Stream<List<CatalogItem>> itemsStream() async* {
    await Future.delayed(const Duration(milliseconds: 350));
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<String> addItem(CatalogItem item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final id = 'itm-${DateTime.now().millisecondsSinceEpoch}';
    _items.insert(
      0,
      CatalogItemModel.fromEntity(item).copyWith(id: id),
    );
    _emit();
    return id;
  }

  @override
  Future<void> updateItem(CatalogItem item) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) _items[index] = item;
    _emit();
  }

  @override
  Future<void> updateStatus(String itemId, String status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) _items[index] = _items[index].copyWith(status: status);
    _emit();
  }

  @override
  Future<void> saveItemPhotos(String itemId, List<String> photos) async {
    if (photos.isEmpty) {
      _photos.remove(itemId);
      return;
    }
    _photos[itemId] = List.unmodifiable(photos);
  }

  @override
  Future<List<String>> itemPhotos(String itemId) async =>
      _photos[itemId] ?? const [];

  final Map<String, List<String>> _photos = {};
}

CatalogItem _item({
  required String id,
  required String name,
  String description = '',
  required String category,
  List<String> occasions = const ['party'],
  required double basePrice,
  required double deposit,
  List<String>? sizes,
  String status = 'available',
  int daysAgo = 30,
}) {
  return CatalogItem(
    id: id,
    name: name,
    description: description,
    category: category,
    occasions: occasions,
    basePrice: basePrice,
    securityDeposit: deposit,
    sizes: sizes ??
        (category == 'kiddie'
            ? const ['2T', '3T', '4T', '5-6', '7-8', '9-10', '11-12']
            : const ['XS', 'S', 'M', 'L', 'XL']),
    status: status,
    createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
  );
}

List<CatalogItem> _seed() {
  return [
    _item(
      id: 'itm-01',
      name: 'Blush Satin Evening Gown',
      description:
          'Floor-length satin gown in soft blush with delicate draping and a subtle side slit. A favorite for debuts and formal evenings.',
      category: 'dress',
      occasions: ['party', 'debut'],
      basePrice: 1800,
      deposit: 1000,
      daysAgo: 2,
    ),
    _item(
      id: 'itm-02',
      name: 'Ivory Lace Wedding Gown',
      description:
          'Timeless ivory gown featuring hand-sewn lace appliqués, a sweetheart neckline, and a chapel-length train.',
      category: 'dress',
      occasions: ['wedding'],
      basePrice: 4500,
      deposit: 2500,
      status: 'rented',
      daysAgo: 4,
    ),
    _item(
      id: 'itm-03',
      name: 'Enchanted Fairy Princess Set',
      description:
          'Sparkling tulle gown with glitter wings and a flower crown. Every little guest will feel like true royalty.',
      category: 'kiddie',
      occasions: ['party', 'costume'],
      basePrice: 650,
      deposit: 400,
      daysAgo: 6,
    ),
    _item(
      id: 'itm-04',
      name: 'Emerald Velvet Evening Dress',
      description:
          'Rich emerald velvet with an elegant off-shoulder cut. Made for unforgettable entrances.',
      category: 'dress',
      occasions: ['party'],
      basePrice: 1600,
      deposit: 900,
      daysAgo: 8,
    ),
    _item(
      id: 'itm-05',
      name: 'Little Royal Knight Costume',
      description:
          'Complete knight set with soft armor pieces, cape, and toy shield. Comfortable enough for a whole day of play.',
      category: 'kiddie',
      occasions: ['costume', 'school'],
      basePrice: 550,
      deposit: 350,
      status: 'rented',
      daysAgo: 10,
    ),
    _item(
      id: 'itm-06',
      name: 'Champagne Mermaid Gown',
      description:
          'Sequin mermaid silhouette in warm champagne tones that catches the light with every step.',
      category: 'dress',
      occasions: ['wedding', 'party'],
      basePrice: 2200,
      deposit: 1200,
      daysAgo: 12,
    ),
    _item(
      id: 'itm-07',
      name: 'Snow White Kiddie Costume',
      description:
          'Classic storybook costume with puffed sleeves and a red hair ribbon. Perfect for school plays and themed parties.',
      category: 'kiddie',
      occasions: ['costume', 'school'],
      basePrice: 480,
      deposit: 300,
      daysAgo: 14,
    ),
    _item(
      id: 'itm-08',
      name: 'Rose Quartz Cocktail Dress',
      description:
          'Knee-length cocktail dress in dusty rose with a fitted bodice and flowing chiffon skirt.',
      category: 'dress',
      occasions: ['party'],
      basePrice: 950,
      deposit: 600,
      status: 'maintenance',
      daysAgo: 16,
    ),
    _item(
      id: 'itm-09',
      name: 'Gardenia Flower Girl Dress',
      description:
          'Soft white tulle flower girl dress with satin sash and scattered pearl details.',
      category: 'kiddie',
      occasions: ['wedding'],
      basePrice: 700,
      deposit: 450,
      daysAgo: 18,
    ),
    _item(
      id: 'itm-10',
      name: 'Pearl White Debut Gown',
      description:
          'Elegant debut gown with beaded bodice and cascading skirt, designed for the celebratory eighteen roses.',
      category: 'dress',
      occasions: ['debut', 'wedding'],
      basePrice: 2800,
      deposit: 1500,
      daysAgo: 20,
    ),
    _item(
      id: 'itm-11',
      name: 'Midnight Navy Tuxedo Gown',
      description:
          'Sophisticated navy gown with tailored lines and subtle gold buttons for a modern formal look.',
      category: 'dress',
      occasions: ['party', 'debut'],
      basePrice: 2000,
      deposit: 1100,
      status: 'rented',
      daysAgo: 22,
    ),
    _item(
      id: 'itm-12',
      name: 'Golden Belle Kids Ballgown',
      description:
          'Storybook ballgown shimmering in gold with layered organza skirts twirl-ready for little dancers.',
      category: 'kiddie',
      occasions: ['party', 'costume'],
      basePrice: 620,
      deposit: 400,
      daysAgo: 24,
    ),
  ];
}

