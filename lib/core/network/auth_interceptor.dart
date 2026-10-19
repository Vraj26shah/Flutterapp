import 'package:dio/dio.dart';
import 'package:shopsphere/core/network/api_endpoints.dart';
import 'package:shopsphere/core/session/session_manager.dart';
import 'package:shopsphere/core/storage/token_storage.dart';

/// Marks a request as protected: the Bearer token is attached and a 401
/// triggers a token refresh + single retry.
const requiresAuthKey = 'requiresAuth';
const _retriedKey = 'authRetried';

/// Attaches the access token and transparently refreshes it on 401.
///
/// A [QueuedInterceptor] processes errors one at a time, so concurrent 401s
/// don't trigger several refreshes. The refresh and the retry go through
/// [_plainDio] (no interceptors) to avoid re-entering this queue.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._tokens, this._session, this._plainDio);

  final TokenStorage _tokens;
  final SessionManager _session;
  final Dio _plainDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[requiresAuthKey] == true) {
      final token = await _tokens.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isProtected = options.extra[requiresAuthKey] == true;
    final alreadyRetried = options.extra[_retriedKey] == true;

    if (err.response?.statusCode != 401 || !isProtected || alreadyRetried) {
      return handler.next(err);
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      await _tokens.clear();
      _session.expire();
      return handler.next(err);
    }

    try {
      options.headers['Authorization'] = 'Bearer $newAccessToken';
      options.extra[_retriedKey] = true;
      final response = await _plainDio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Returns the new access token, or `null` if refreshing failed (e.g. 403).
  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) return null;
    try {
      final response = await _plainDio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {
          'refreshToken': refreshToken,
          'expiresInMins': ApiEndpoints.tokenExpiryMins,
        },
      );
      final data = response.data;
      final access = data?['accessToken'] as String?;
      final refresh = data?['refreshToken'] as String?;
      if (access == null || refresh == null) return null;
      await _tokens.saveTokens(accessToken: access, refreshToken: refresh);
      return access;
    } on DioException {
      return null;
    }
  }
}
