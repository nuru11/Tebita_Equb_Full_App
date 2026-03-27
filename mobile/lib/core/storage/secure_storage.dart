import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for access token, refresh token, and optional user JSON.
class SecureStorage {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user';

  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  Future<String?> getUserJson() => _storage.read(key: _keyUser);

  Future<void> setAccessToken(String value) =>
      _storage.write(key: _keyAccessToken, value: value);
  Future<void> setRefreshToken(String value) =>
      _storage.write(key: _keyRefreshToken, value: value);
  Future<void> setUserJson(String value) =>
      _storage.write(key: _keyUser, value: value);

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUser);
  }
}
