import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/network/auth_interceptor.dart';
import 'package:shopsphere/core/session/session_manager.dart';

import '../../helpers/mocks.dart';

/// Fake transport that answers requests from a handler, recording each one.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  late MockTokenStorage tokens;
  late SessionManager session;

  setUp(() {
    tokens = MockTokenStorage();
    session = SessionManager();
    when(() => tokens.readAccessToken()).thenAnswer((_) async => 'old-access');
    when(() => tokens.readRefreshToken()).thenAnswer((_) async => 'refresh');
    when(
      () => tokens.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => tokens.clear()).thenAnswer((_) async {});
  });

  ApiClient clientWith(FakeAdapter adapter) {
    final plain = Dio(BaseOptions(baseUrl: 'https://test'))
      ..httpClientAdapter = adapter;
    final dio = Dio(BaseOptions(baseUrl: 'https://test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(tokens, session, plain));
    return ApiClient(dio);
  }

  test('attaches the Bearer token to protected requests only', () async {
    final adapter = FakeAdapter((_) => json(200, {'ok': true}));
    final client = clientWith(adapter);

    await client.get('/auth/me', requiresAuth: true);
    await client.get('/products');

    expect(adapter.requests[0].headers['Authorization'], 'Bearer old-access');
    expect(adapter.requests[1].headers['Authorization'], isNull);
  });

  test('on 401 refreshes the token and retries the original request', () async {
    final adapter = FakeAdapter((o) {
      if (o.path == '/auth/refresh') {
        return json(200, {'accessToken': 'new', 'refreshToken': 'new-r'});
      }
      final auth = o.headers['Authorization'];
      return auth == 'Bearer new'
          ? json(200, {'id': 1})
          : json(401, {'message': 'Token Expired!'});
    });

    final data = await clientWith(adapter).get('/auth/me', requiresAuth: true);

    expect(data, {'id': 1});
    expect(adapter.requests.map((r) => r.path), [
      '/auth/me',
      '/auth/refresh',
      '/auth/me',
    ]);
    verify(() => tokens.saveTokens(accessToken: 'new', refreshToken: 'new-r'))
        .called(1);
  });

  test(
    'when refresh fails with 403 it clears tokens and expires the session',
    () async {
      final adapter = FakeAdapter(
        (o) => o.path == '/auth/refresh'
            ? json(403, {'message': 'Invalid refresh token'})
            : json(401, {'message': 'Invalid/Expired Token!'}),
      );
      final expired = expectLater(
        session.onSessionExpired,
        emits(isA<String>()),
      );

      await expectLater(
        clientWith(adapter).get('/auth/me', requiresAuth: true),
        throwsA(isA<UnauthorizedException>()),
      );
      await expired;
      verify(() => tokens.clear()).called(1);
    },
  );
}
