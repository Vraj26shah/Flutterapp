import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shopsphere/core/error/exceptions.dart';

/// Converts a [DioException] into one of our typed [AppException]s.
AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const RequestTimeoutException();
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      return _fromStatus(e.response?.statusCode, _messageOf(e.response?.data));
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      final inner = e.error;
      if (inner is AppException) return inner;
      if (inner is SocketException || inner is HttpException) {
        return const NetworkException();
      }
      if (inner is FormatException) return const ParseException();
      return ServerException(message: e.message ?? 'Unknown network error');
  }
}

AppException _fromStatus(int? status, String? message) => switch (status) {
  400 => BadRequestException(message ?? 'Bad request'),
  401 || 403 => UnauthorizedException(message ?? 'Session expired'),
  404 => NotFoundException(message ?? 'Not found'),
  _ => ServerException(
    statusCode: status,
    message: message ?? 'Server error ($status)',
  ),
};

String? _messageOf(Object? data) {
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  return null;
}
