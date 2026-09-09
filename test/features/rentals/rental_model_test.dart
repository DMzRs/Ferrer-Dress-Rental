import 'package:ferrer_rental_shop/features/rentals/data/models/rental_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _fullMap() => {
      'userId': 'u1',
      'userName': 'Jane',
      'itemId': 'i1',
      'itemName': 'Gown',
      'itemCategory': 'dress',
      'startDate': DateTime(2026, 9, 7),
      'endDate': DateTime(2026, 9, 10),
      'rentalFee': 1500,
      'securityDeposit': 1000,
      'total': 2500,
      'status': 'active',
      'deliveryAddress': 'QC',
      'createdAt': DateTime(2026, 9, 1),
    };

void main() {
  group('RentalModel.fromMap', () {
    test('parses full map', () {
      final m = RentalModel.fromMap('r1', _fullMap());
      expect(m.id, 'r1');
      expect(m.userName, 'Jane');
      expect(m.itemName, 'Gown');
      expect(m.totalDays, 4);
      expect(m.returnedAt, isNull);
    });

    test('applies defaults for missing keys', () {
      final m = RentalModel.fromMap('r2', {});
      expect(m.userId, '');
      expect(m.itemCategory, 'dress');
      expect(m.rentalFee, 0);
      expect(m.status, 'active');
    });

    test('parses ISO strings and numeric strings', () {
      final m = RentalModel.fromMap('r3', {
        'startDate': '2026-09-07T00:00:00.000',
        'endDate': '2026-09-08T00:00:00.000',
        'rentalFee': '500',
        'securityDeposit': '1000',
        'total': '1500',
        'createdAt': '2026-09-01T00:00:00.000',
      });
      expect(m.startDate, DateTime(2026, 9, 7));
      expect(m.rentalFee, 500);
      expect(m.total, 1500);
    });

    test('parses returnedAt when present', () {
      final m = RentalModel.fromMap(
        'r4',
        {..._fullMap(), 'returnedAt': DateTime(2026, 9, 11)},
      );
      expect(m.returnedAt, DateTime(2026, 9, 11));
    });
  });

  group('RentalModel mapping', () {
    test('fromEntity copies fields', () {
      final src = RentalModel.fromMap('r5', _fullMap());
      final copy = RentalModel.fromEntity(src);
      expect(copy.id, 'r5');
      expect(copy.total, 2500);
    });

    test('copyWith overrides and can clear returnedAt', () {
      final src = RentalModel.fromMap(
        'r6',
        {..._fullMap(), 'returnedAt': DateTime(2026, 9, 11)},
      );
      expect(src.copyWith(status: 'completed').status, 'completed');
      expect(
        src.copyWith(clearReturnedAt: true).returnedAt,
        isNull,
      );
    });

    test('toMap round-trips (non-firestore) and omits null returnedAt', () {
      final src = RentalModel.fromMap('r7', _fullMap());
      final map = src.toMap();
      expect(map.containsKey('returnedAt'), isFalse);
      final rt = RentalModel.fromMap('r7', map);
      expect(rt.itemId, 'i1');
      expect(rt.total, 2500);

      final withReturn = src.copyWith(returnedAt: DateTime(2026, 9, 11));
      expect(withReturn.toMap().containsKey('returnedAt'), isTrue);
    });
  });
}
