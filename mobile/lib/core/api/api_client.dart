import 'package:dio/dio.dart';

import 'retry_interceptor.dart';

Dio createApiClient({String? baseUrl}) {
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
    ),
  );

  dio.interceptors.add(RetryInterceptor(dio: dio));

  return dio;
}
