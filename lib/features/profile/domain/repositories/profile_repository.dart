import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';

abstract interface class ProfileRepository {
  /// The signed-in user (`GET /auth/me`).
  Future<Result<User>> getProfile();
}
