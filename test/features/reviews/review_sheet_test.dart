import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/data/datasources/mock_review_data_source.dart';
import 'package:ferrer_rental_shop/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/usecases/submit_review_usecase.dart';
import 'package:ferrer_rental_shop/features/reviews/presentation/viewmodels/review_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('submit stores review and clears error', () async {
    final repo = ReviewRepositoryImpl(MockReviewDataSource());
    final vm = ReviewViewModel(
      submit: SubmitReviewUseCase(repo),
      reviews: repo,
      rental: Rental(
          id: 'rx',
          userId: 'u1',
          userName: 'M',
          itemId: 'i1',
          itemName: 'G',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 5),
          rentalFee: 1,
          securityDeposit: 1,
          total: 2,
          status: 'completed',
          createdAt: DateTime(2026, 8, 1)),
      userId: 'u1',
    );
    final ok = await vm.send(4, 'Nice');
    expect(ok, isTrue);
    expect(vm.error, isNull);
    expect(vm.submitting, isFalse);
    expect((await repo.reviewForRentalStream('rx').first)?.stars, 4);
    vm.dispose();
  });

  test('submit with no stars sets error', () async {
    final repo = ReviewRepositoryImpl(MockReviewDataSource());
    final vm = ReviewViewModel(
      submit: SubmitReviewUseCase(repo),
      reviews: repo,
      rental: Rental(
          id: 'rx',
          userId: 'u1',
          userName: 'M',
          itemId: 'i1',
          itemName: 'G',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 5),
          rentalFee: 1,
          securityDeposit: 1,
          total: 2,
          status: 'completed',
          createdAt: DateTime(2026, 8, 1)),
      userId: 'u1',
    );
    addTearDown(vm.dispose);
    final ok = await vm.send(0, '');
    expect(ok, isFalse);
    expect(vm.error, isNotNull);
  });
}
