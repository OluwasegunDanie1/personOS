/// Thrown when the backend's standard error envelope
/// ({success:false, error:{code,message,details?}}) is parsed successfully.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.details, this.statusCode});

  final String code;
  final String message;
  final Object? details;
  final int? statusCode;

  @override
  String toString() => 'ApiException($code): $message';
}

/// Thrown when a response cannot be interpreted as either the approved
/// success or error envelope shape.
class MalformedResponseException implements Exception {
  const MalformedResponseException(this.message);

  final String message;

  @override
  String toString() => 'MalformedResponseException: $message';
}

/// Thrown for transport-level failures (no HTTP response was ever received).
class NetworkException implements Exception {
  const NetworkException(this.message);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}
