import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/session/session_manager.dart';
import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';
import 'package:shopsphere/features/auth/domain/usecases/auth_usecases.dart';
import 'package:shopsphere/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shopsphere/features/auth/presentation/bloc/login_cubit.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockCheckSessionUseCase checkSession;
  late MockLogoutUseCase logout;
  late SessionManager session;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const LoginParams(username: '', password: ''));
  });

  setUp(() {
    checkSession = MockCheckSessionUseCase();
    logout = MockLogoutUseCase();
    session = SessionManager();
    when(() => logout(any())).thenAnswer((_) async => const Ok(null));
  });

  AuthBloc build() => AuthBloc(
    checkSession: checkSession,
    logout: logout,
    sessionManager: session,
    splashMinDuration: Duration.zero,
  );

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'routes to Home when a session is stored',
      setUp: () => when(
        () => checkSession(any()),
      ).thenAnswer((_) async => const Ok(true)),
      build: build,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthState.authenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'routes to Login when there is no session',
      setUp: () => when(
        () => checkSession(any()),
      ).thenAnswer((_) async => const Ok(false)),
      build: build,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthState.unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'signs out with a message when the network layer expires the session',
      build: build,
      seed: () => const AuthState.authenticated(),
      act: (_) => session.expire('Session expired'),
      expect: () => [
        const AuthState.unauthenticated(message: 'Session expired'),
      ],
      verify: (_) => verify(() => logout(any())).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'logout clears the session',
      build: build,
      seed: () => const AuthState.authenticated(),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        isA<AuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.unauthenticated,
        ),
      ],
    );
  });

  group('LoginCubit', () {
    late MockLoginUseCase login;
    const user = User(
      id: 1,
      username: 'emilys',
      email: '',
      firstName: 'Emily',
      lastName: 'Johnson',
      image: '',
    );

    setUp(() => login = MockLoginUseCase());

    blocTest<LoginCubit, LoginState>(
      'emits [submitting, success] on valid credentials',
      setUp: () =>
          when(() => login(any())).thenAnswer((_) async => const Ok(user)),
      build: () => LoginCubit(login),
      act: (cubit) => cubit.submit(username: 'emilys', password: 'emilyspass'),
      expect: () => const [
        LoginState(status: LoginStatus.submitting),
        LoginState(status: LoginStatus.success, user: user),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'emits [submitting, failure] on invalid credentials',
      setUp: () => when(
        () => login(any()),
      ).thenAnswer((_) async => const Err(InvalidCredentialsFailure())),
      build: () => LoginCubit(login),
      act: (cubit) => cubit.submit(username: 'emilys', password: 'nope123'),
      expect: () => const [
        LoginState(status: LoginStatus.submitting),
        LoginState(
          status: LoginStatus.failure,
          failure: InvalidCredentialsFailure(),
        ),
      ],
    );
  });
}
