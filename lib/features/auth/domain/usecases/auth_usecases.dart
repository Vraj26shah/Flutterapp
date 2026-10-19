import 'package:equatable/equatable.dart';
import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';
import 'package:shopsphere/features/auth/domain/repositories/auth_repository.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

class LoginUseCase implements UseCase<User, LoginParams> {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User>> call(LoginParams params) => _repository.login(
    username: params.username.trim(),
    password: params.password,
  );
}

class CheckSessionUseCase implements UseCase<bool, NoParams> {
  const CheckSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<bool>> call(NoParams params) async =>
      Ok(await _repository.hasSession());
}

class LogoutUseCase implements UseCase<void, NoParams> {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.logout();
}
