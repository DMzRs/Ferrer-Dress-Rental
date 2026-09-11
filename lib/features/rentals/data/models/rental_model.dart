import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';

class RentalModel extends Rental {
  const RentalModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.itemId,
    required super.itemName,
    super.itemCategory,
    required super.startDate,
    required super.endDate,
    required super.rentalFee,
    required super.securityDeposit,
    required super.total,
    required super.status,
    super.deliveryAddress,
    required super.createdAt,
    super.returnedAt,
    super.declineReason,
  });

  factory RentalModel.fromMap(String id, Map<String, dynamic> map) {
    return RentalModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      userName: (map['userName'] ?? '') as String,
      itemId: (map['itemId'] ?? '') as String,
      itemName: (map['itemName'] ?? '') as String,
      itemCategory: (map['itemCategory'] ?? 'dress') as String,
      startDate: _toDate(map['startDate']),
      endDate: _toDate(map['endDate']),
      rentalFee: _toDouble(map['rentalFee']),
      securityDeposit: _toDouble(map['securityDeposit']),
      total: _toDouble(map['total']),
      status: (map['status'] ?? 'active') as String,
      deliveryAddress: (map['deliveryAddress'] ?? '') as String,
      createdAt: _toDate(map['createdAt']),
      returnedAt: map['returnedAt'] == null ? null : _toDate(map['returnedAt']),
      declineReason: (map['declineReason'] ?? '') as String,
    );
  }

  factory RentalModel.fromEntity(Rental r) {
    return RentalModel(
      id: r.id,
      userId: r.userId,
      userName: r.userName,
      itemId: r.itemId,
      itemName: r.itemName,
      itemCategory: r.itemCategory,
      startDate: r.startDate,
      endDate: r.endDate,
      rentalFee: r.rentalFee,
      securityDeposit: r.securityDeposit,
      total: r.total,
      status: r.status,
      deliveryAddress: r.deliveryAddress,
      createdAt: r.createdAt,
      returnedAt: r.returnedAt,
      declineReason: r.declineReason,
    );
  }

  RentalModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? itemId,
    String? itemName,
    String? itemCategory,
    DateTime? startDate,
    DateTime? endDate,
    double? rentalFee,
    double? securityDeposit,
    double? total,
    String? status,
    String? deliveryAddress,
    DateTime? createdAt,
    DateTime? returnedAt,
    bool clearReturnedAt = false,
    String? declineReason,
  }) {
    return RentalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rentalFee: rentalFee ?? this.rentalFee,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdAt: createdAt ?? this.createdAt,
      returnedAt: clearReturnedAt ? null : (returnedAt ?? this.returnedAt),
      declineReason: declineReason ?? this.declineReason,
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
    dynamic encode(DateTime date) =>
        forFirestore ? Timestamp.fromDate(date) : date.toIso8601String();
    final map = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'itemId': itemId,
      'itemName': itemName,
      'itemCategory': itemCategory,
      'startDate': encode(startDate),
      'endDate': encode(endDate),
      'rentalFee': rentalFee,
      'securityDeposit': securityDeposit,
      'total': total,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'createdAt': encode(createdAt),
      if (returnedAt != null) 'returnedAt': encode(returnedAt!),
    };
    if (declineReason.isNotEmpty) {
      map['declineReason'] = declineReason;
    }
    return map;
  }
}

