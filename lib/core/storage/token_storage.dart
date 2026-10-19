import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction over where auth tokens live, so it can be mocked in tests.
abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> saveUserId(int id);
  Future<int?> readUserId();
  Future<void> clear();
}

/// Stores tokens in the platform keystore (Android Keystore / iOS Keychain).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  @override
  Future<void> saveUserId(int id) =>
      _storage.write(key: _userIdKey, value: '$id');

  @override
  Future<int?> readUserId() async =>
      int.tryParse(await _storage.read(key: _userIdKey) ?? '');

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userIdKey);
  }
}
