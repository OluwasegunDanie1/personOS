import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the access and refresh tokens using platform secure storage
/// (Keychain on iOS, EncryptedSharedPreferences/Keystore on Android). Tokens
/// must never be stored in SharedPreferences or logged.
class SecureTokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'relvio.auth.accessToken';
  static const _refreshTokenKey = 'relvio.auth.refreshToken';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
