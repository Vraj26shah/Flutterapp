import 'package:shopsphere/core/error/failure_mapper.dart';
import 'package:shopsphere/core/storage/token_storage.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';
import 'package:shopsphere/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this._remote, required this._tokens});

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) => guard(() async {
    final response = await _remote.login(
      username: username,
      password: password,
    );
    await _tokens.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    await _tokens.saveUserId(response.user.id);
    return response.user;
  });

  @override
  Future<bool> hasSession() async {
    try {
      final token = await _tokens.readAccessToken();
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Result<void>> logout() => guard(_tokens.clear);
}
