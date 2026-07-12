import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart'
    hide Options;
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/api/auth_interceptor.dart';
import 'package:relvio/core/storage/secure_token_storage.dart';

/// A scripted [HttpClientAdapter]: each call is answered by a handler
/// keyed on the request path, so tests can simulate 401-then-refresh
/// sequences without any real network I/O or extra test dependency.
class _ScriptedAdapter implements HttpClientAdapter {
  final Map<String, Future<ResponseBody> Function(RequestOptions options)> handlers = {};
  final Map<String, int> callCounts = {};

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    callCounts.update(options.path, (count) => count + 1, ifAbsent: () => 1);
    final handler = handlers[options.path];
    if (handler == null) {
      throw StateError('No scripted handler for ${options.path}');
    }
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

void main() {
  late Dio dio;
  late _ScriptedAdapter adapter;
  late SecureTokenStorage tokenStorage;
  late int invalidateCount;

  setUp(() async {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    tokenStorage = SecureTokenStorage(const FlutterSecureStorage());
    await tokenStorage.saveTokens(accessToken: 'stale-access', refreshToken: 'valid-refresh');

    invalidateCount = 0;
    adapter = _ScriptedAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        onSessionInvalidated: () async {
          invalidateCount++;
        },
      ),
    );
  });

  test('attaches the stored access token to outgoing requests', () async {
    String? authorizationHeader;
    adapter.handlers['/x'] = (options) async {
      authorizationHeader = options.headers['Authorization'] as String?;
      return _jsonBody({'success': true, 'data': {}}, 200);
    };

    await dio.get<dynamic>('/x');

    expect(authorizationHeader, 'Bearer stale-access');
  });

  test('a 401 triggers exactly one refresh and retries the original request with the new token', () async {
    var xCallCount = 0;
    adapter.handlers['/x'] = (options) async {
      xCallCount++;
      final header = options.headers['Authorization'] as String?;
      if (header == 'Bearer fresh-access') {
        return _jsonBody({'success': true, 'data': {'ok': true}}, 200);
      }
      return _jsonBody({
        'success': false,
        'error': {'code': 'INVALID_ACCESS_TOKEN', 'message': 'expired'},
      }, 401);
    };
    adapter.handlers['/auth/refresh'] = (options) async =>
        _jsonBody({'success': true, 'data': {'accessToken': 'fresh-access', 'refreshToken': 'fresh-refresh'}}, 200);

    final response = await dio.get<dynamic>('/x');

    expect(response.statusCode, 200);
    expect(xCallCount, 2, reason: 'one failing attempt plus one retry after refresh');
    expect(adapter.callCounts['/auth/refresh'], 1);
    expect(await tokenStorage.readAccessToken(), 'fresh-access');
    expect(await tokenStorage.readRefreshToken(), 'fresh-refresh');
    expect(invalidateCount, 0);
  });

  test('concurrent 401s share a single in-flight refresh call (single-flight)', () async {
    adapter.handlers['/x'] = (options) async {
      final header = options.headers['Authorization'] as String?;
      if (header == 'Bearer fresh-access') {
        return _jsonBody({'success': true, 'data': {'ok': true}}, 200);
      }
      return _jsonBody({
        'success': false,
        'error': {'code': 'INVALID_ACCESS_TOKEN', 'message': 'expired'},
      }, 401);
    };
    adapter.handlers['/auth/refresh'] = (options) async =>
        _jsonBody({'success': true, 'data': {'accessToken': 'fresh-access', 'refreshToken': 'fresh-refresh'}}, 200);

    final results = await Future.wait([dio.get<dynamic>('/x'), dio.get<dynamic>('/x')]);

    expect(results.every((r) => r.statusCode == 200), isTrue);
    expect(adapter.callCounts['/auth/refresh'], 1);
  });

  test('refresh failure invalidates the session and propagates the original 401', () async {
    adapter.handlers['/x'] = (options) async => _jsonBody({
      'success': false,
      'error': {'code': 'INVALID_ACCESS_TOKEN', 'message': 'expired'},
    }, 401);
    adapter.handlers['/auth/refresh'] = (options) async => _jsonBody({
      'success': false,
      'error': {'code': 'INVALID_REFRESH_TOKEN', 'message': 'invalid'},
    }, 401);

    await expectLater(dio.get<dynamic>('/x'), throwsA(isA<DioException>()));

    expect(invalidateCount, 1);
  });

  test('the refresh request itself is never retried or re-triggers a refresh', () async {
    adapter.handlers['/auth/refresh'] = (options) async => _jsonBody({
      'success': false,
      'error': {'code': 'INVALID_REFRESH_TOKEN', 'message': 'invalid'},
    }, 401);

    await expectLater(
      dio.post<dynamic>('/auth/refresh', data: {}, options: Options(extra: {skipAuthExtraKey: true})),
      throwsA(isA<DioException>()),
    );

    expect(adapter.callCounts['/auth/refresh'], 1);
    expect(invalidateCount, 0, reason: 'skipAuth requests must bypass the interceptor entirely');
  });
}
