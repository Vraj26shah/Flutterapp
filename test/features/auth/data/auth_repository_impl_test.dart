import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/auth/data/models/user_model.dart';
import 'package:shopsphere/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';

import '../../../helpers/fixture_reader.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRemoteDataSource remote;
  late MockTokenStorage tokens;
  late AuthRepositoryImpl repository;

  final response = LoginResponseModel.fromJson(fixtureMap('login.json'));

  setUp(() {
    remote = MockAuthRemoteDataSource();
    tokens = MockTokenStorage();
    repository = AuthRepositoryImpl(remote: remote, tokens: tokens);
    when(
      () => tokens.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => tokens.saveUserId(any())).thenAnswer((_) async {});
    when(() => tokens.clear()).thenAnswer((_) async {});
  });

  Future<Result<User>> login() =>
      repository.login(username: 'emilys', password: 'emilyspass');

  test('login stores tokens and user id, returns the user', () async {
    when(
      () => remote.login(username: 'emilys', password: 'emilyspass'),
    ).thenAnswer((_) async => response);

    final result = await login();

    expect((result as Ok<User>).data.username, 'emilys');
    verify(
      () => tokens.saveTokens(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
      ),
    ).called(1);
    verify(() => tokens.saveUserId(1)).called(1);
  });

  test('HTTP 400 becomes InvalidCredentialsFailure and stores nothing', () async {
    when(
      () => remote.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const BadRequestException('Invalid credentials'));

    final result = await login();

    expect(
      (result as Err).failure,
      const InvalidCredentialsFailure('Invalid username or password'),
    );
    verifyNever(
      () => tokens.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    );
  });

  test('no internet becomes NetworkFailure', () async {
    when(
      () => remote.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const NetworkException());

    expect((await login() as Err).failure, isA<NetworkFailure>());
  });

  test('hasSession reflects the stored access token', () async {
    when(() => tokens.readAccessToken()).thenAnswer((_) async => 'token');
    expect(await repository.hasSession(), isTrue);

    when(() => tokens.readAccessToken()).thenAnswer((_) async => null);
    expect(await repository.hasSession(), isFalse);
  });

  test('logout clears the stored session', () async {
    final result = await repository.logout();

    expect(result.isOk, isTrue);
    verify(() => tokens.clear()).called(1);
  });
}
