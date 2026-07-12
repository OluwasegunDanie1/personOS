import 'package:dio/dio.dart';

import 'api_exceptions.dart';

/// Unwraps the approved Relvio backend success envelope
/// ({success:true, data, meta?}) and returns the raw `data` payload.
///
/// Throws [ApiException] when the envelope explicitly reports failure, and
/// [MalformedResponseException] when the body does not match either the
/// approved success or error envelope shape.
dynamic unwrapEnvelope(Response<dynamic> response) {
  final body = response.data;

  if (body is! Map<String, dynamic>) {
    throw const MalformedResponseException('The server returned a non-JSON-object response body.');
  }

  final success = body['success'];

  if (success == true) {
    return body['data'];
  }

  if (success == false) {
    throw errorFromEnvelope(body, response.statusCode);
  }

  throw const MalformedResponseException('The response body did not contain the approved success/error envelope.');
}

ApiException errorFromEnvelope(Map<String, dynamic> body, int? statusCode) {
  final error = body['error'];

  if (error is Map<String, dynamic>) {
    return ApiException(
      code: (error['code'] as String?) ?? 'UNKNOWN_ERROR',
      message: (error['message'] as String?) ?? 'An unknown error occurred.',
      details: error['details'],
      statusCode: statusCode,
    );
  }

  return ApiException(code: 'UNKNOWN_ERROR', message: 'An unknown error occurred.', statusCode: statusCode);
}

/// Maps a [DioException] (thrown by Dio itself, before/without a parsed
/// envelope) to an approved Relvio exception type. A DioException carrying a
/// real HTTP response is mapped through the same error-envelope parsing as a
/// successful-transport-but-failed-request case; anything without a response
/// is a genuine network/transport failure.
Exception mapDioException(DioException error) {
  final response = error.response;

  if (response != null) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      try {
        return errorFromEnvelope(body, response.statusCode);
      } catch (_) {
        // fall through to malformed-response handling below
      }
    }
    return const MalformedResponseException('The server returned an unexpected error response.');
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException('Unable to reach the Relvio server. Check your connection and try again.');
    case DioExceptionType.cancel:
      return const NetworkException('The request was cancelled.');
    default:
      return NetworkException(error.message ?? 'A network error occurred.');
  }
}
