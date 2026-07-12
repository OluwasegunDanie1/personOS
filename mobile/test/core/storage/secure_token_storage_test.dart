// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/storage/secure_token_storage.dart';

void main() {
  late SecureTokenStorage storage;

  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    storage = SecureTokenStorage(const FlutterSecureStorage());
  });

  test('reads return null before anything is saved', () async {
    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
  });

  test('saveTokens persists both tokens for later reads', () async {
    await storage.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');

    expect(await storage.readAccessToken(), 'access-1');
    expect(await storage.readRefreshToken(), 'refresh-1');
  });

  test('saveTokens overwrites a prior rotation (refresh-token rotation contract)', () async {
    await storage.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
    await storage.saveTokens(accessToken: 'access-2', refreshToken: 'refresh-2');

    expect(await storage.readAccessToken(), 'access-2');
    expect(await storage.readRefreshToken(), 'refresh-2');
  });

  test('clear removes both tokens', () async {
    await storage.saveTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
    await storage.clear();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
  });
}
