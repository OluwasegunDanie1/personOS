import 'package:dio/dio.dart';

import '../storage/secure_token_storage.dart';
import 'auth_interceptor.dart';
import 'retry_interceptor.dart';

/// Builds the single shared Dio client used by every Relvio API service.
/// baseUrl must be supplied externally (never hard-coded); the approved
/// convention is `--dart-define=API_BASE_URL=<server origin>`.
Dio createApiClient({String? baseUrl, SecureTokenStorage? tokenStorage, Future<void> Function()? onSessionInvalidated}) {
  final resolvedBaseUrl =
      baseUrl ?? const String.fromEnvironment('API_BASE_URL');

  if (resolvedBaseUrl.isEmpty) {
    throw StateError(
      'API_BASE_URL is required. Provide it with '
      '--dart-define=API_BASE_URL=<server origin>.',
    );
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: '$resolvedBaseUrl/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(RetryInterceptor(dio: dio));

  if (tokenStorage != null && onSessionInvalidated != null) {
    dio.interceptors.add(
      AuthInterceptor(dio: dio, tokenStorage: tokenStorage, onSessionInvalidated: onSessionInvalidated),
    );
  }

  return dio;
}
