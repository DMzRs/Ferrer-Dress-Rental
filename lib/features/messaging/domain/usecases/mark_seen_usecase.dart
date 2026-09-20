import 'package:ferrer_rental_shop/features/messaging/domain/repositories/message_repository.dart';

class MarkSeenUseCase {
  const MarkSeenUseCase(this._repository);

  final MessageRepository _repository;

  Future<void> execute(String threadUserId, String role) =>
      _repository.markSeen(threadUserId, role);
}
