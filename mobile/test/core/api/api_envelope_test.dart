import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/api/api_envelope.dart';
import 'package:relvio/core/api/api_exceptions.dart';

Response<dynamic> _responseWith(dynamic data, {int? statusCode}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/test'),
    data: data,
    statusCode: statusCode,
  );
}

void main() {
  group('unwrapEnvelope', () {
    test('returns the data payload of a success envelope', () {
      final data = unwrapEnvelope(_responseWith({'success': true, 'data': {'totalPeople': 3}}));
      expect(data, {'totalPeople': 3});
    });

    test('throws ApiException for an error envelope', () {
      final response = _responseWith({
        'success': false,
        'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Bad credentials'},
      }, statusCode: 401);

      expect(
        () => unwrapEnvelope(response),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'INVALID_CREDENTIALS')
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('throws MalformedResponseException for a non-object body', () {
      expect(() => unwrapEnvelope(_responseWith('not-json')), throwsA(isA<MalformedResponseException>()));
    });

    test('throws MalformedResponseException when success flag is missing', () {
      expect(() => unwrapEnvelope(_responseWith({'data': {}})), throwsA(isA<MalformedResponseException>()));
    });
  });

  group('mapDioException', () {
    test('maps a response-carrying error through the error envelope', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: _responseWith({
          'success': false,
          'error': {'code': 'USER_DISABLED', 'message': 'Disabled'},
        }, statusCode: 403),
      );

      expect(mapDioException(dioError), isA<ApiException>().having((e) => e.code, 'code', 'USER_DISABLED'));
    });

    test('maps a connection timeout with no response to NetworkException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(mapDioException(dioError), isA<NetworkException>());
    });
  });
}
