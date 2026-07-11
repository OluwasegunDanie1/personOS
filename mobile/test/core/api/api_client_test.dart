import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/core/api/api_client.dart';

void main() {
  test('throws when API_BASE_URL is not provided', () {
    expect(() => createApiClient(), throwsStateError);
  });

  test('composes the base URL with the approved /api/v1 path', () {
    final dio = createApiClient(baseUrl: 'https://api.relvio.test');

    expect(dio.options.baseUrl, 'https://api.relvio.test/api/v1');
  });

  test('configures the approved 30-second timeouts', () {
    final dio = createApiClient(baseUrl: 'https://api.relvio.test');

    expect(dio.options.connectTimeout, const Duration(seconds: 30));
    expect(dio.options.receiveTimeout, const Duration(seconds: 30));
  });
}
