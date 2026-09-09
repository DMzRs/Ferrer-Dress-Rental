import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ferrer_rental_shop/features/inventory/domain/entities/catalog_item.dart';

class CatalogItemModel extends CatalogItem {
  const CatalogItemModel({
    required super.id,
    required super.name,
    super.description,
    required super.category,
    super.occasions,
    required super.basePrice,
    required super.securityDeposit,
    super.sizes,
    super.thumbnail,
    super.status,
    required super.createdAt,
  });

  factory CatalogItemModel.fromMap(String id, Map<String, dynamic> map) {
    return CatalogItemModel(
      id: id,
      name: (map['name'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      category: (map['category'] ?? 'dress') as String,
      occasions:
          ((map['occasions'] as List?) ?? []).map((e) => e.toString()).toList(),
      basePrice: _toDouble(map['basePrice']),
      securityDeposit: _toDouble(map['securityDeposit']),
      sizes: ((map['sizes'] as List?) ?? []).map((e) => e.toString()).toList(),
      thumbnail: (map['thumbnail'] ?? '') as String,
      status: (map['status'] ?? 'available') as String,
      createdAt: _toDate(map['createdAt']),
    );
  }

  factory CatalogItemModel.fromEntity(CatalogItem entity) {
    return CatalogItemModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      category: entity.category,
      occasions: entity.occasions,
      basePrice: entity.basePrice,
      securityDeposit: entity.securityDeposit,
      sizes: entity.sizes,
      thumbnail: entity.thumbnail,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap({bool forFirestore = false}) {
    return {
      'name': name,
      'description': description,
      'category': category,
      'occasions': occasions,
      'basePrice': basePrice,
      'securityDeposit': securityDeposit,
      'sizes': sizes,
      'thumbnail': thumbnail,
      'status': status,
      'createdAt': forFirestore ? Timestamp.fromDate(createdAt) : createdAt.toIso8601String(),
    };
  }
}

