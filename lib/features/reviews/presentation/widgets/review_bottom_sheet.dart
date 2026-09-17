import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/widgets/top_snackbar.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/entities/rental_entity.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/repositories/review_repository.dart';
import 'package:ferrer_rental_shop/features/reviews/domain/usecases/submit_review_usecase.dart';
import 'package:ferrer_rental_shop/features/reviews/presentation/viewmodels/review_viewmodel.dart';

/// Opens the rate/edit-rating sheet for a completed rental.
/// Returns true when a rating was saved.
Future<bool> showReviewSheet({
  required BuildContext context,
  required Rental rental,
  required String userId,
}) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => ChangeNotifierProvider<ReviewViewModel>(
      create: (_) => ReviewViewModel(
        submit: context.read<SubmitReviewUseCase>(),
        reviews: context.read<ReviewRepository>(),
        rental: rental,
        userId: userId,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: const _ReviewSheetBody(),
      ),
    ),
  );
  if (result != null && context.mounted) {
    await showAppSnackBar(
      context,
      result == 'pending'
          ? 'Your rating was saved.'
          : 'Thank you for your feedback.',
      backgroundColor:
          result == 'pending' ? AppColors.gold : AppColors.success,
    );
  }
  return result != null;
}

class _ReviewSheetBody extends StatefulWidget {
  const _ReviewSheetBody();

  @override
  State<_ReviewSheetBody> createState() => _ReviewSheetBodyState();
}

class _ReviewSheetBodyState extends State<_ReviewSheetBody> {
  int _stars = 0;
  late final TextEditingController _comment;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _comment = TextEditingController();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewViewModel>();
    if (!_initialized && !vm.loading) {
      _initialized = true;
      _stars = vm.existing?.stars ?? 0;
      _comment.text = vm.existing?.comment ?? '';
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.champagne,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              vm.existing == null ? 'Rate Your Rental' : 'Update Your Rating',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              vm.rental.itemName,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _stars;
                return IconButton(
                  key: ValueKey('star-$i'),
                  icon: Icon(
                    filled
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: filled ? AppColors.gold : AppColors.inkSoft,
                    size: 40,
                  ),
                  onPressed: vm.submitting
                      ? null
                      : () => setState(() => _stars = i + 1),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 3,
              maxLength: 500,
              enabled: !vm.submitting,
              decoration: const InputDecoration(
                hintText: 'How was the fit and quality? (optional)',
              ),
            ),
            if (vm.error != null) ...[
              const SizedBox(height: 8),
              Text(
                vm.error!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.submitting
                    ? null
                    : () async {
                        final ok =
                            await vm.send(_stars, _comment.text);
                        if (ok && context.mounted) {
                          Navigator.of(context).pop(
                            vm.savedWithPendingCount
                                ? 'pending'
                                : 'saved',
                          );
                        }
                      },
                child: vm.submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(vm.existing == null ? 'Submit Rating' : 'Update Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
