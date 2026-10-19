import 'package:shopsphere/core/error/failure_mapper.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/network/api_endpoints.dart';
import 'package:shopsphere/core/storage/token_storage.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/diagnostics/domain/diagnostics.dart';

/// Hits DummyJSON's test endpoints through the real network stack
/// (same client, interceptors and error mapping as the rest of the app).
class DiagnosticsRepositoryImpl implements DiagnosticsRepository {
  const DiagnosticsRepositoryImpl({
    required this._client,
    required this._tokens,
  });

  final ApiClient _client;
  final TokenStorage _tokens;

  @override
  Future<Result<String>> run(ErrorScenario scenario) => guard(() async {
    switch (scenario) {
      case ErrorScenario.serverError:
        await _client.get('/http/500');
        return 'Unexpectedly succeeded';
      case ErrorScenario.notFound:
        await _client.get('/http/404');
        return 'Unexpectedly succeeded';
      case ErrorScenario.slowNetwork:
        final watch = Stopwatch()..start();
        await _client.get(
          ApiEndpoints.products,
          query: {'delay': 3000, 'limit': 1, 'select': 'title'},
        );
        final seconds = (watch.elapsedMilliseconds / 1000).toStringAsFixed(1);
        return 'Loaded after ${seconds}s — the loader stayed visible.';
      case ErrorScenario.expiredSession:
        // Replace the real tokens with invalid ones: /auth/me returns 401,
        // the interceptor tries to refresh, gets 403 and signs the user out.
        await _tokens.saveTokens(
          accessToken: 'expired-access-token',
          refreshToken: 'invalid-refresh-token',
        );
        await _client.get(ApiEndpoints.me, requiresAuth: true);
        return 'Session is still valid';
    }
  });
}
