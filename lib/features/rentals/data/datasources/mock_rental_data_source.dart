import 'dart:async';

import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/rentals/data/models/rental_model.dart';
import 'rental_data_source.dart';

class MockRentalDataSource implements RentalDataSource {
  MockRentalDataSource();

  final List<Rental> _rentals = [];
  final StreamController<List<Rental>> _controller =
      StreamController<List<Rental>>.broadcast();
  bool _seeded = false;

  void _ensureSeed() {
    if (_seeded) return;
    _seeded = true;
    final now = DateTime.now();

    Rental build({
      required String id,
      required String userId,
      required String userName,
      required String itemId,
      required String itemName,
      required String itemCategory,
      required int startOffset,
      required int endOffset,
      required double fee,
      required double deposit,
      required String status,
      int createdDaysAgo = 1,
      DateTime? returnedAt,
    }) {
      return Rental(
        id: id,
        userId: userId,
        userName: userName,
        itemId: itemId,
        itemName: itemName,
        itemCategory: itemCategory,
        startDate: now.add(Duration(days: startOffset)),
        endDate: now.add(Duration(days: endOffset)),
        rentalFee: fee,
        securityDeposit: deposit,
        total: fee + deposit,
        status: status,
        createdAt: now.subtract(Duration(days: createdDaysAgo)),
        returnedAt: returnedAt,
      );
    }

    _rentals.addAll([
      build(
        id: 'rnt-01',
        userId: 'user-001',
        userName: 'Maria Santos',
        itemId: 'itm-02',
        itemName: 'Ivory Lace Wedding Gown',
        itemCategory: 'dress',
        startOffset: -2,
        endOffset: 4,
        fee: 27000,
        deposit: 2500,
        status: 'active',
        createdDaysAgo: 3,
      ),
      build(
        id: 'rnt-02',
        userId: 'user-001',
        userName: 'Maria Santos',
        itemId: 'itm-03',
        itemName: 'Enchanted Fairy Princess Set',
        itemCategory: 'kiddie',
        startOffset: -6,
        endOffset: -1,
        fee: 1950,
        deposit: 400,
        status: 'active',
        createdDaysAgo: 8,
      ),
      build(
        id: 'rnt-03',
        userId: 'user-001',
        userName: 'Maria Santos',
        itemId: 'itm-06',
        itemName: 'Champagne Mermaid Gown',
        itemCategory: 'dress',
        startOffset: -30,
        endOffset: -25,
        fee: 11000,
        deposit: 1200,
        status: 'completed',
        createdDaysAgo: 34,
        returnedAt: now.subtract(const Duration(days: 25)),
      ),
      build(
        id: 'rnt-04',
        userId: 'user-002',
        userName: 'Angela Reyes',
        itemId: 'itm-11',
        itemName: 'Midnight Navy Tuxedo Gown',
        itemCategory: 'dress',
        startOffset: -1,
        endOffset: 2,
        fee: 6000,
        deposit: 1100,
        status: 'active',
        createdDaysAgo: 5,
      ),
      build(
        id: 'rnt-05',
        userId: 'user-003',
        userName: 'Joshua Dela Cruz',
        itemId: 'itm-05',
        itemName: 'Little Royal Knight Costume',
        itemCategory: 'kiddie',
        startOffset: -9,
        endOffset: -2,
        fee: 3850,
        deposit: 350,
        status: 'active',
        createdDaysAgo: 12,
      ),
      build(
        id: 'rnt-06',
        userId: 'user-002',
        userName: 'Angela Reyes',
        itemId: 'itm-10',
        itemName: 'Pearl White Debut Gown',
        itemCategory: 'dress',
        startOffset: -70,
        endOffset: -65,
        fee: 14000,
        deposit: 1500,
        status: 'completed',
        createdDaysAgo: 74,
        returnedAt: now.subtract(const Duration(days: 65)),
      ),
    ]);
    scheduleMicrotask(_emit);
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_rentals));
    }
  }

  @override
  Stream<List<Rental>> userRentalsStream(String userId) async* {
    _ensureSeed();
    await Future.delayed(const Duration(milliseconds: 300));
    yield _rentals.where((r) => r.userId == userId).toList();
    await for (final list in _controller.stream) {
      yield list.where((r) => r.userId == userId).toList();
    }
  }

  @override
  Stream<List<Rental>> allRentalsStream() async* {
    _ensureSeed();
    await Future.delayed(const Duration(milliseconds: 300));
    yield List.unmodifiable(_rentals);
    yield* _controller.stream;
  }

  @override
  Future<void> createRental(Rental rental) async {
    _ensureSeed();
    await Future.delayed(const Duration(milliseconds: 600));
    final id = 'rnt-${DateTime.now().millisecondsSinceEpoch}';
    _rentals.insert(0, RentalModel.fromEntity(rental).copyWith(id: id));
    _emit();
    // NOTE: item status flips live in the use-case layer (same as Firebase),
    // so this data source never touches inventory — no double writes.
  }

  @override
  Future<void> completeRental(String rentalId, {DateTime? returnedAt}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _rentals.indexWhere((r) => r.id == rentalId);
    if (index != -1) {
      final rental = _rentals[index];
      _rentals[index] = RentalModel.fromEntity(rental).copyWith(
        status: 'completed',
        returnedAt: returnedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _emit();
    }
  }

  @override
  Future<void> cancelRental(String rentalId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _rentals.indexWhere((r) => r.id == rentalId);
    if (index != -1) {
      final rental = _rentals[index];
      _rentals[index] = RentalModel.fromEntity(rental).copyWith(
        status: 'cancelled',
        updatedAt: DateTime.now(),
      );
      _emit();
    }
  }

  @override
  Future<void> updateRentalStatus(
    String rentalId,
    String status, {
    String? declineReason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _rentals.indexWhere((r) => r.id == rentalId);
    if (index != -1) {
      final rental = _rentals[index];
      _rentals[index] = RentalModel.fromEntity(rental).copyWith(
        status: status,
        updatedAt: DateTime.now(),
        declineReason: declineReason?.trim().isNotEmpty == true
            ? declineReason!.trim()
            : rental.declineReason,
      );
      _emit();
    }
  }
}

