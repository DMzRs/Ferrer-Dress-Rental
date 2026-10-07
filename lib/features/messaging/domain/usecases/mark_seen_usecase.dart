import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';

/// Marks a thread read for one side without write loops.
class MarkSeenUseCase {
  const MarkSeenUseCase(this._repository);

  final MessageRepository _repository;

  /// Records the given role's read timestamp for a thread.
  Future<void> execute(String threadUserId, String role) =>
      _repository.markSeen(threadUserId, role);
}
