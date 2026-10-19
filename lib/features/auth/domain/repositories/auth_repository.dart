import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';

abstract interface class AuthRepository {
  /// Signs in and persists the tokens securely.
  Future<Result<User>> login({
    required String username,
    required String password,
  });

  /// Whether a stored session (access token) exists.
  Future<bool> hasSession();

  /// Clears tokens and any local session data.
  Future<Result<void>> logout();
}
