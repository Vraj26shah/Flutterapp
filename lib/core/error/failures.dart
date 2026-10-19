import 'package:equatable/equatable.dart';

/// Domain-level failures. Pure Dart, safe to use from the domain and
/// presentation layers. Each carries a user-friendly [message].
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  /// Whether retrying the same action could succeed.
  bool get isRetryable => true;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'You are offline. Check your connection and try again.',
  ]);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'The server is taking too long to respond. Please retry.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong on our side. Please try again.',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'We could not find that item.']);

  @override
  bool get isRetryable => false;
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([
    super.message = 'Invalid username or password',
  ]);

  @override
  bool get isRetryable => false;
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]);

  @override
  bool get isRetryable => false;
}

class ParseFailure extends Failure {
  const ParseFailure([
    super.message = 'We received an unexpected response. Please try again.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not access local storage.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
