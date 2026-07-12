import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/features/organizations/organizations_api.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    lastRequest = options;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Map<String, dynamic> body, int statusCode) => ResponseBody.fromString(
  jsonEncode(body),
  statusCode,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  test('list() parses each membership summary including nested role', () async {
    final adapter = _FakeAdapter(
      (options) async => _jsonBody({
        'success': true,
        'data': {
          'organizations': [
            {
              'id': 'org-1',
              'name': 'Grace Church',
              'logoUrl': null,
              'role': {'id': 'role-1', 'name': 'Owner'},
            },
          ],
        },
      }, 200),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

    final organizations = await OrganizationsApi(dio).list();

    expect(organizations, hasLength(1));
    expect(organizations.single.id, 'org-1');
    expect(organizations.single.name, 'Grace Church');
    expect(organizations.single.logoUrl, isNull);
    expect(organizations.single.role.name, 'Owner');
    expect(adapter.lastRequest!.path, '/organizations');
    expect(adapter.lastRequest!.method, 'GET');
  });

  test('create() posts the name and parses the narrow detail shape', () async {
    final adapter = _FakeAdapter(
      (options) async => _jsonBody({
        'success': true,
        'data': {
          'organization': {'id': 'org-2', 'name': 'New Org'},
        },
      }, 201),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

    final created = await OrganizationsApi(dio).create('New Org');

    expect(created.id, 'org-2');
    expect(created.name, 'New Org');
    expect(adapter.lastRequest!.method, 'POST');
    expect(adapter.lastRequest!.data, {'name': 'New Org'});
  });

  test('detail() and update() hit the expected organization-scoped paths', () async {
    final adapter = _FakeAdapter(
      (options) async => _jsonBody({
        'success': true,
        'data': {
          'organization': {'id': 'org-3', 'name': 'Detail Org'},
        },
      }, 200),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

    await OrganizationsApi(dio).detail('org-3');
    expect(adapter.lastRequest!.path, '/organizations/org-3');
    expect(adapter.lastRequest!.method, 'GET');

    await OrganizationsApi(dio).update('org-3', 'Renamed');
    expect(adapter.lastRequest!.path, '/organizations/org-3');
    expect(adapter.lastRequest!.method, 'PATCH');
    expect(adapter.lastRequest!.data, {'name': 'Renamed'});
  });
}
