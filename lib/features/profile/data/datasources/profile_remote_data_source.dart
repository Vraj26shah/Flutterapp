import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/network/api_endpoints.dart';
import 'package:shopsphere/features/auth/data/models/user_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<UserModel> getMe();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<UserModel> getMe() async {
    final data = await _client.get(ApiEndpoints.me, requiresAuth: true);
    if (data is! Map<String, dynamic>) throw const ParseException();
    return UserModel.fromJson(data);
  }
}
