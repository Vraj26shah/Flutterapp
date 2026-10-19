import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shopsphere/core/network/api_endpoints.dart';
import 'package:shopsphere/core/network/auth_interceptor.dart';
import 'package:shopsphere/core/network/dio_error_mapper.dart';
import 'package:shopsphere/core/session/session_manager.dart';
import 'package:shopsphere/core/storage/token_storage.dart';

/// Thin wrapper over [Dio] used by every remote data source.
///
/// It is the only place that knows about Dio: every [DioException] is
/// converted to a typed [AppException] before leaving this class.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool requiresAuth = false,
  }) => _send(
    () => _dio.get<dynamic>(
      path,
      queryParameters: query,
      options: Options(extra: {requiresAuthKey: requiresAuth}),
    ),
  );

  Future<dynamic> post(
    String path, {
    Object? data,
    bool requiresAuth = false,
  }) => _send(
    () => _dio.post<dynamic>(
      path,
      data: data,
      options: Options(extra: {requiresAuthKey: requiresAuth}),
    ),
  );

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

/// Default timeouts. `?delay=5000` (DummyJSON max) still fits inside them.
const _connectTimeout = Duration(seconds: 15);
const _receiveTimeout = Duration(seconds: 20);

BaseOptions _baseOptions() => BaseOptions(
  baseUrl: ApiEndpoints.baseUrl,
  connectTimeout: _connectTimeout,
  receiveTimeout: _receiveTimeout,
  sendTimeout: _connectTimeout,
  contentType: Headers.jsonContentType,
  responseType: ResponseType.json,
);

/// Builds the single configured [Dio] instance used by the app.
Dio buildDio({
  required TokenStorage tokenStorage,
  required SessionManager sessionManager,
}) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(tokenStorage, sessionManager, Dio(_baseOptions())),
  );
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }
  return dio;
}
