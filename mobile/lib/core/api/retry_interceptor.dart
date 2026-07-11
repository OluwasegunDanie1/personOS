import 'package:dio/dio.dart';

const _retryAttemptKey = 'retryAttempt';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, this.maxRetries = 2});

  final Dio dio;
  final int maxRetries;

  bool shouldRetry(DioException error, int attempt) {
    final isGet = error.requestOptions.method.toUpperCase() == 'GET';
    return isGet && attempt < maxRetries && _isTransientNetworkFailure(error);
  }

  bool _isTransientNetworkFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra[_retryAttemptKey] as int?) ?? 0;

    if (!shouldRetry(err, attempt)) {
      handler.next(err);
      return;
    }

    err.requestOptions.extra[_retryAttemptKey] = attempt + 1;

    try {
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
