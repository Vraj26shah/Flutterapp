import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/session/session_manager.dart';
import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/features/auth/domain/usecases/auth_usecases.dart';

// ---------------------------------------------------------------- events
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired by the splash screen to decide between Home and Login.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Fired after a successful login.
final class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn();
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// The network layer could not refresh the session (401 / 403).
final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

// ----------------------------------------------------------------- state
enum AuthStatus { unknown, authenticated, unauthenticated }

final class AuthState extends Equatable {
  const AuthState._(this.status, [this.message]);

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.authenticated() : this._(AuthStatus.authenticated);
  const AuthState.unauthenticated({String? message})
    : this._(AuthStatus.unauthenticated, message);

  final AuthStatus status;

  /// Optional explanation shown on the login screen (e.g. session expired).
  final String? message;

  @override
  List<Object?> get props => [status, message];
}

// ------------------------------------------------------------------ bloc
/// App-wide authentication status. Drives the root navigation gate.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this._checkSession,
    required this._logout,
    required SessionManager sessionManager,
    this._splashMinDuration = const Duration(milliseconds: 900),
  }) : super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoggedIn>((_, emit) => emit(const AuthState.authenticated()));
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionExpired>(_onExpired);
    _expirySub = sessionManager.onSessionExpired.listen(
      (reason) => add(AuthSessionExpired(reason)),
    );
  }

  final CheckSessionUseCase _checkSession;
  final LogoutUseCase _logout;
  final Duration _splashMinDuration;
  late final StreamSubscription<String> _expirySub;

  Future<void> _onCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Run the check alongside a short minimum splash so the brand is visible.
    final (result, _) = await (
      _checkSession(const NoParams()),
      Future<void>.delayed(_splashMinDuration),
    ).wait;
    final hasSession = result.fold((_) => false, (value) => value);
    emit(
      hasSession
          ? const AuthState.authenticated()
          : const AuthState.unauthenticated(),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout(const NoParams());
    emit(const AuthState.unauthenticated(message: 'You have been signed out.'));
  }

  Future<void> _onExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.unauthenticated) return;
    await _logout(const NoParams());
    emit(AuthState.unauthenticated(message: event.reason));
  }

  @override
  Future<void> close() async {
    await _expirySub.cancel();
    return super.close();
  }
}
