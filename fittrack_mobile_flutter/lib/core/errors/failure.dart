sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

class UnimplementedFailure extends Failure {
  const UnimplementedFailure(super.message);
}

class ApiResult<T> {
  const ApiResult.success(this.data) : failure = null;
  const ApiResult.failure(this.failure) : data = null;
  final T? data;
  final Failure? failure;
  bool get isSuccess => failure == null;
}

class FailureException implements Exception {
  const FailureException(this.failure);
  final Failure failure;

  @override
  String toString() => failure.message;
}

String failureMessage(Object error) {
  if (error is FailureException) return error.failure.message;
  if (error is Failure) return error.message;
  return 'Une erreur inattendue est survenue.';
}
