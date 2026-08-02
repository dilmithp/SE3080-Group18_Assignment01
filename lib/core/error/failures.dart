/// Domain-safe error types returned by repositories via `Either<Failure, T>`
/// (see package:dartz). Repositories catch data-layer exceptions and map
/// them to one of these — the domain and presentation layers never see a
/// raw [Exception].
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connection.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'You do not have permission to do that.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested resource was not found.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong. Please try again.']);
}
