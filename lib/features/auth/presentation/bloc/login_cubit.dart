import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';
import 'package:shopsphere/features/auth/domain/usecases/auth_usecases.dart';

enum LoginStatus { idle, submitting, success, failure }

final class LoginState extends Equatable {
  const LoginState({this.status = LoginStatus.idle, this.failure, this.user});

  final LoginStatus status;
  final Failure? failure;
  final User? user;

  bool get isSubmitting => status == LoginStatus.submitting;

  @override
  List<Object?> get props => [status, failure, user];
}

/// Handles the login form submission only; app-wide auth lives in AuthBloc.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._login) : super(const LoginState());

  final LoginUseCase _login;

  Future<void> submit({
    required String username,
    required String password,
  }) async {
    if (state.isSubmitting) return;
    emit(const LoginState(status: LoginStatus.submitting));
    final result = await _login(
      LoginParams(username: username, password: password),
    );
    switch (result) {
      case Ok(:final data):
        emit(LoginState(status: LoginStatus.success, user: data));
      case Err(:final failure):
        emit(LoginState(status: LoginStatus.failure, failure: failure));
    }
  }
}

/// Pure validation helpers (unit-testable, no Flutter dependency).
abstract final class LoginValidators {
  static const minUsername = 3;
  static const minPassword = 6;

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your username';
    if (v.length < minUsername) {
      return 'Username must be at least $minUsername characters';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter your password';
    if (v.length < minPassword) {
      return 'Password must be at least $minPassword characters';
    }
    return null;
  }
}
