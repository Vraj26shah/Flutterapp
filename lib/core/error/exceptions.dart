/// Low-level exceptions thrown by the data layer.
///
/// These never reach the UI: repositories convert them to domain
/// [Failure]s via `mapExceptionToFailure`.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No connectivity / socket could not be opened.
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// Connect / send / receive timeout.
class RequestTimeoutException extends AppException {
  const RequestTimeoutException([super.message = 'The request timed out']);
}

/// HTTP 400 (bad request), e.g. invalid login credentials.
class BadRequestException extends AppException {
  const BadRequestException([super.message = 'Bad request']);
}

/// HTTP 401 / 403 — the session is invalid or could not be refreshed.
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired']);
}

/// HTTP 404.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']);
}

/// HTTP 5xx or any other unexpected status code.
class ServerException extends AppException {
  const ServerException({
    this.statusCode,
    String message = 'Something went wrong on our side',
  }) : super(message);

  final int? statusCode;
}

/// The response body did not match the expected schema.
class ParseException extends AppException {
  const ParseException([super.message = 'Unexpected response format']);
}

/// Local persistence (Hive / secure storage) failed.
class CacheException extends AppException {
  const CacheException([super.message = 'Local storage error']);
}
