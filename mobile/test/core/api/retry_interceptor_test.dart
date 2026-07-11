import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/api/retry_interceptor.dart';

void main() {
  late Dio dio;
  late RetryInterceptor interceptor;

  setUp(() {
    dio = Dio();
    interceptor = RetryInterceptor(dio: dio);
  });

  DioException errorFor({
    required String method,
    required DioExceptionType type,
  }) {
    final requestOptions = RequestOptions(path: '/people', method: method);
    return DioException(requestOptions: requestOptions, type: type);
  }

  test('retries GET requests on transient network failures', () {
    final error = errorFor(
      method: 'GET',
      type: DioExceptionType.connectionTimeout,
    );

    expect(interceptor.shouldRetry(error, 0), isTrue);
  });

  test('stops retrying once the maximum attempt count is reached', () {
    final error = errorFor(
      method: 'GET',
      type: DioExceptionType.connectionTimeout,
    );

    expect(interceptor.shouldRetry(error, interceptor.maxRetries), isFalse);
  });

  test('does not retry mutation methods', () {
    for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      final error = errorFor(
        method: method,
        type: DioExceptionType.connectionTimeout,
      );

      expect(interceptor.shouldRetry(error, 0), isFalse);
    }
  });

  test('does not retry deterministic bad responses', () {
    final error = errorFor(method: 'GET', type: DioExceptionType.badResponse);

    expect(interceptor.shouldRetry(error, 0), isFalse);
  });
}
