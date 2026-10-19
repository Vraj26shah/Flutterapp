import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';
import 'package:shopsphere/features/auth/domain/usecases/auth_usecases.dart';
import 'package:shopsphere/features/auth/presentation/bloc/login_cubit.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;

  const user = User(
    id: 1,
    username: 'emilys',
    email: 'e@x.com',
    firstName: 'Emily',
    lastName: 'Johnson',
    image: '',
  );

  setUp(() => repository = MockAuthRepository());

  test('LoginUseCase trims the username before calling the API', () async {
    when(() => repository.login(username: 'emilys', password: 'emilyspass'))
        .thenAnswer((_) async => const Ok(user));

    final result = await LoginUseCase(repository)(
      const LoginParams(username: '  emilys ', password: 'emilyspass'),
    );

    expect((result as Ok<User>).data, user);
  });

  test('LoginUseCase propagates InvalidCredentialsFailure', () async {
    when(
      () => repository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Err(InvalidCredentialsFailure()));

    final result = await LoginUseCase(repository)(
      const LoginParams(username: 'emilys', password: 'wrongpass'),
    );

    expect((result as Err).failure, isA<InvalidCredentialsFailure>());
  });

  test('CheckSessionUseCase wraps hasSession', () async {
    when(() => repository.hasSession()).thenAnswer((_) async => true);

    final result = await CheckSessionUseCase(repository)(const NoParams());

    expect((result as Ok<bool>).data, isTrue);
  });

  group('LoginValidators', () {
    test('username', () {
      expect(LoginValidators.username(''), isNotNull);
      expect(LoginValidators.username('ab'), contains('at least'));
      expect(LoginValidators.username('emilys'), isNull);
    });

    test('password', () {
      expect(LoginValidators.password(null), isNotNull);
      expect(LoginValidators.password('12345'), contains('at least'));
      expect(LoginValidators.password('emilyspass'), isNull);
    });
  });
}
