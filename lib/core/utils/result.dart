import '../error/failure.dart';

/// Success/failure result wrapper.
sealed class Result<T> {
  const Result();

  /// Whether the result holds data.
  bool get isSuccess;

  /// Failure cause, or null on success.
  Failure? get failure;
}

/// Successful result carrying data.
class Success<T> extends Result<T> {
  /// Payload returned on success.
  final T data;
  const Success(this.data);

  @override
  /// Whether the result holds data.
  bool get isSuccess => true;

  @override
  /// Failure cause, or null on success.
  Failure? get failure => null;
}

/// Failed result carrying a failure.
class Err<T> extends Result<T> {
  final Failure _failure;
  const Err(this._failure);

  @override
  /// Whether the result holds data.
  bool get isSuccess => false;

  @override
  /// Failure cause, or null on success.
  Failure? get failure => _failure;
}
