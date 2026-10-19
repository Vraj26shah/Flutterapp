import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/error/failure_mapper.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/network/dio_error_mapper.dart';

DioException _response(int status, [Object? data]) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  final options = RequestOptions(path: '/x');

  group('mapDioException', () {
    test('maps status codes to typed exceptions', () {
      expect(
        mapDioException(_response(400, {'message': 'Invalid credentials'})),
        isA<BadRequestException>(),
      );
      expect(mapDioException(_response(401)), isA<UnauthorizedException>());
      expect(mapDioException(_response(403)), isA<UnauthorizedException>());
      expect(mapDioException(_response(404)), isA<NotFoundException>());
      expect(
        mapDioException(_response(500)),
        isA<ServerException>().having((e) => e.statusCode, 'status', 500),
      );
    });

    test('maps timeouts and connection errors', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ]) {
        expect(
          mapDioException(DioException(requestOptions: options, type: type)),
          isA<RequestTimeoutException>(),
        );
      }
      expect(
        mapDioException(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
        isA<NetworkException>(),
      );
    });
  });

  group('mapExceptionToFailure', () {
    test('turns exceptions into user-facing failures', () {
      expect(
        mapExceptionToFailure(const BadRequestException('Invalid credentials')),
        const InvalidCredentialsFailure(),
      );
      expect(
        mapExceptionToFailure(const NetworkException()),
        isA<NetworkFailure>(),
      );
      expect(
        mapExceptionToFailure(const FormatException()),
        isA<ParseFailure>(),
      );
      expect(mapExceptionToFailure(Exception('?')), isA<UnknownFailure>());
    });

    test('non-retryable failures hide the retry button', () {
      expect(const NotFoundFailure().isRetryable, isFalse);
      expect(const ServerFailure().isRetryable, isTrue);
    });
  });
}
