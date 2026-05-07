// lib/domain/errors/failures.dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ApiFailure extends Failure {
  const ApiFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
