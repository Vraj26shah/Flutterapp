import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/network/api_endpoints.dart';
import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';
import 'package:shopsphere/features/cart/data/datasources/cart_data_sources.dart';
import 'package:shopsphere/features/cart/data/models/cart_item_model.dart';
import 'package:shopsphere/features/diagnostics/data/diagnostics_repository_impl.dart';
import 'package:shopsphere/features/diagnostics/domain/diagnostics.dart';
import 'package:shopsphere/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:shopsphere/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:shopsphere/features/profile/domain/usecases/get_profile_usecase.dart';

import '../helpers/fixture_reader.dart';
import '../helpers/mocks.dart';

void main() {
  late MockApiClient client;

  setUp(() => client = MockApiClient());

  test('AuthRemoteDataSource posts credentials with expiresInMins', () async {
    when(() => client.post(ApiEndpoints.login, data: any(named: 'data')))
        .thenAnswer((_) async => fixtureMap('login.json'));

    final response = await AuthRemoteDataSourceImpl(client)
        .login(username: 'emilys', password: 'emilyspass');

    expect(response.user.username, 'emilys');
    final body =
        verify(() => client.post(any(), data: captureAny(named: 'data')))
                .captured
                .single
            as Map<String, dynamic>;
    expect(body, {
      'username': 'emilys',
      'password': 'emilyspass',
      'expiresInMins': 30,
    });
  });

  test('CartRemoteDataSource sends userId and product quantities', () async {
    when(() => client.post(ApiEndpoints.addCart, data: any(named: 'data')))
        .thenAnswer((_) async => fixtureMap('cart_add.json'));

    await CartRemoteDataSourceImpl(client).addCart(
      userId: 1,
      items: const [
        CartItemModel(
          productId: 144,
          title: 'Cricket Helmet',
          thumbnail: '',
          price: 44.99,
          discountPercentage: 9.64,
          quantity: 2,
          stock: 10,
        ),
      ],
    );

    final body =
        verify(() => client.post(any(), data: captureAny(named: 'data')))
                .captured
                .single
            as Map<String, dynamic>;
    expect(body, {
      'userId': 1,
      'products': [
        {'id': 144, 'quantity': 2},
      ],
    });
  });

  group('profile', () {
    test('GET /auth/me is a protected request', () async {
      when(() => client.get(ApiEndpoints.me, requiresAuth: true)).thenAnswer(
        (_) async => {...fixtureMap('login.json'), 'phone': '+81 965'},
      );

      final repository = ProfileRepositoryImpl(
        ProfileRemoteDataSourceImpl(client),
      );
      final result = await GetProfileUseCase(repository)(const NoParams());

      expect((result as Ok<User>).data.phone, '+81 965');
    });

    test('a 401 surfaces as UnauthorizedFailure', () async {
      when(() => client.get(ApiEndpoints.me, requiresAuth: true))
          .thenThrow(const UnauthorizedException());

      final result = await ProfileRepositoryImpl(
        ProfileRemoteDataSourceImpl(client),
      ).getProfile();

      expect((result as Err).failure, isA<UnauthorizedFailure>());
    });
  });

  group('DiagnosticsRepository', () {
    late MockTokenStorage tokens;
    late DiagnosticsRepositoryImpl repository;

    setUp(() {
      tokens = MockTokenStorage();
      repository = DiagnosticsRepositoryImpl(client: client, tokens: tokens);
    });

    test('/http/500 is reported as ServerFailure', () async {
      when(() => client.get('/http/500'))
          .thenThrow(const ServerException(statusCode: 500));

      final result = await repository.run(ErrorScenario.serverError);

      expect((result as Err).failure, isA<ServerFailure>());
    });

    test('expired session swaps tokens then calls /auth/me', () async {
      when(
        () => tokens.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});
      when(() => client.get(ApiEndpoints.me, requiresAuth: true))
          .thenThrow(const UnauthorizedException());

      final result = await repository.run(ErrorScenario.expiredSession);

      expect((result as Err).failure, isA<UnauthorizedFailure>());
      verify(
        () => tokens.saveTokens(
          accessToken: 'expired-access-token',
          refreshToken: 'invalid-refresh-token',
        ),
      ).called(1);
    });
  });
}
