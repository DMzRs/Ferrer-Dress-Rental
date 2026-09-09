class CatalogItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> occasions;
  final double basePrice;
  final double securityDeposit;
  final List<String> sizes;

  /// Small preview image (data URI or URL) stored with the item doc so
  /// catalog lists stay light. Full photos live in itemPhotos/{id}.
  final String thumbnail;
  final String status;
  final DateTime createdAt;

  const CatalogItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.occasions = const [],
    required this.basePrice,
    required this.securityDeposit,
    this.sizes = const [],
    this.thumbnail = '',
    this.status = 'available',
    required this.createdAt,
  });

  bool get isAvailable => status == 'available';
  bool get isDress => category == 'dress';

  String get statusLabel {
    switch (status) {
      case 'rented':
        return 'Rented';
      case 'maintenance':
        return 'Maintenance';
      case 'scheduled_for_appointment':
        return 'Scheduled for Appointment';
      default:
        return 'Available';
    }
  }

  /// Shorter variant for tight badges on catalog cards.
  String get shortStatusLabel {
    switch (status) {
      case 'scheduled_for_appointment':
        return 'Scheduled';
      default:
        return statusLabel;
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'kiddie':
        return 'Kiddie Costume';
      default:
        return 'Adult Dress';
    }
  }

  CatalogItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    List<String>? occasions,
    double? basePrice,
    double? securityDeposit,
    List<String>? sizes,
    String? thumbnail,
    String? status,
    DateTime? createdAt,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      occasions: occasions ?? this.occasions,
      basePrice: basePrice ?? this.basePrice,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      sizes: sizes ?? this.sizes,
      thumbnail: thumbnail ?? this.thumbnail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
