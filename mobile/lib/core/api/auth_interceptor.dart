import 'package:dio/dio.dart';

import '../storage/secure_token_storage.dart';
import 'api_envelope.dart';

/// Request-level flag: marks a request as not requiring an access token and
/// not eligible for 401-triggered refresh (used for /auth/login,
/// /auth/refresh, /auth/logout — all @Public() on the backend).
const skipAuthExtraKey = 'relvio.skipAuth';

/// Request-level flag: marks a request that has already been retried once
/// after a refresh, to prevent retry loops.
const _retriedExtraKey = 'relvio.retriedAfterRefresh';

/// Attaches the access token to authenticated requests and performs a
/// single-flight refresh-and-retry-once on a 401 response.
///
/// Single-flight: if multiple requests fail with 401 concurrently, only one
/// refresh call executes; the others await the same in-flight Future. The
/// refresh request itself is marked [skipAuthExtraKey] so it is never
/// access-token-attached and never recursively triggers another refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, required this.tokenStorage, required this.onSessionInvalidated});

  final Dio dio;
  final SecureTokenStorage tokenStorage;
  final Future<void> Function() onSessionInvalidated;

  Future<bool>? _refreshInFlight;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[skipAuthExtraKey] == true) {
      handler.next(options);
      return;
    }

    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isAuthEndpoint = err.requestOptions.extra[skipAuthExtraKey] == true;
    final alreadyRetried = err.requestOptions.extra[_retriedExtraKey] == true;
    final isUnauthorized = err.response?.statusCode == 401;

    if (isAuthEndpoint || alreadyRetried || !isUnauthorized) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshOnce();

    if (!refreshed) {
      await onSessionInvalidated();
      handler.next(err);
      return;
    }

    final newAccessToken = await tokenStorage.readAccessToken();
    if (newAccessToken == null) {
      await onSessionInvalidated();
      handler.next(err);
      return;
    }

    final retryOptions = err.requestOptions;
    retryOptions.extra[_retriedExtraKey] = true;
    retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

    try {
      final response = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Single-flight: concurrent callers share the same in-flight refresh
  /// result rather than each issuing their own /auth/refresh call.
  Future<bool> _refreshOnce() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      return false;
    }

    try {
      final response = await dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {skipAuthExtraKey: true}),
      );

      final data = unwrapEnvelope(response) as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      // Rotation: the old refresh token must never be reused once replaced.
      await tokenStorage.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
      return true;
    } on DioException {
      return false;
    }
  }
}
