import '../error/failure.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess;

  Failure? get failure;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  bool get isSuccess => true;

  @override
  Failure? get failure => null;
}

class Err<T> extends Result<T> {
  final Failure _failure;
  const Err(this._failure);

  @override
  bool get isSuccess => false;

  @override
  Failure? get failure => _failure;
}
