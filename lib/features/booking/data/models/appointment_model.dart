import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ferrer_rental_shop/features/booking/domain/entities/appointment_entity.dart';

class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.id,
    required super.userId,
    required super.userName,
    super.itemId,
    super.itemName,
    required super.purpose,
    required super.scheduledAt,
    required super.status,
    super.declineReason,
    required super.createdAt,
  });

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AppointmentModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      userName: (map['userName'] ?? '') as String,
      itemId: map['itemId'] as String?,
      itemName: map['itemName'] as String?,
      purpose: (map['purpose'] ?? 'Measuring') as String,
      scheduledAt: _toDate(map['scheduledAt']),
      status: (map['status'] ?? 'scheduled') as String,
      declineReason: (map['declineReason'] ?? '') as String,
      createdAt: _toDate(map['createdAt']),
    );
  }

  factory AppointmentModel.fromEntity(Appointment a) {
    return AppointmentModel(
      id: a.id,
      userId: a.userId,
      userName: a.userName,
      itemId: a.itemId,
      itemName: a.itemName,
      purpose: a.purpose,
      scheduledAt: a.scheduledAt,
      status: a.status,
      declineReason: a.declineReason,
      createdAt: a.createdAt,
    );
  }

  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? itemId,
    String? itemName,
    bool clearItem = false,
    String? purpose,
    DateTime? scheduledAt,
    String? status,
    String? declineReason,
    bool clearDeclineReason = false,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      itemId: clearItem ? null : (itemId ?? this.itemId),
      itemName: clearItem ? null : (itemName ?? this.itemName),
      purpose: purpose ?? this.purpose,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      declineReason: clearDeclineReason ? '' : (declineReason ?? this.declineReason),
      createdAt: createdAt ?? this.createdAt,
    );
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
    return {
      'userId': userId,
      'userName': userName,
      if (itemId != null) 'itemId': itemId,
      if (itemName != null) 'itemName': itemName,
      'purpose': purpose,
      'scheduledAt': encode(scheduledAt),
      'status': status,
      if (declineReason.isNotEmpty) 'declineReason': declineReason,
      'createdAt': encode(createdAt),
    };
  }
}

