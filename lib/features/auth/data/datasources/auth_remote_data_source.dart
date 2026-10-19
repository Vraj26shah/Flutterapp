import 'package:shopsphere/core/error/exceptions.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/network/api_endpoints.dart';
import 'package:shopsphere/features/auth/data/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String username,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<LoginResponseModel> login({
    required String username,
    required String password,
  }) async {
    final data = await _client.post(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
        'expiresInMins': ApiEndpoints.tokenExpiryMins,
      },
    );
    if (data is! Map<String, dynamic>) throw const ParseException();
    return LoginResponseModel.fromJson(data);
  }
}
