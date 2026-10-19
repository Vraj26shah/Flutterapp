import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';

/// Maps a data-layer [AppException] to a domain [Failure].
Failure mapExceptionToFailure(Object error) => switch (error) {
  NetworkException() => const NetworkFailure(),
  RequestTimeoutException() => const TimeoutFailure(),
  BadRequestException(:final message) => InvalidCredentialsFailure(
    message.toLowerCase().contains('credential')
        ? 'Invalid username or password'
        : message,
  ),
  UnauthorizedException() => const UnauthorizedFailure(),
  NotFoundException() => const NotFoundFailure(),
  ServerException() => const ServerFailure(),
  ParseException() => const ParseFailure(),
  CacheException() => const CacheFailure(),
  FormatException() || TypeError() => const ParseFailure(),
  _ => const UnknownFailure(),
};

/// Runs [action] and converts any thrown exception into an [Err].
///
/// Used by every repository implementation so failure handling is uniform.
Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    return Ok(await action());
  } catch (error) {
    return Err(mapExceptionToFailure(error));
  }
}
