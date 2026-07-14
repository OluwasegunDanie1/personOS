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

  group('listMembers() (Product Task 052)', () {
    test('hits the organization-scoped members path and parses each member exactly', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'members': [
              {
                'membershipId': 'membership-1',
                'user': {'id': 'user-1', 'firstName': 'Ada', 'lastName': 'Lovelace', 'email': 'ada@example.com'},
                'role': {'id': 'role-1', 'name': 'Owner'},
              },
            ],
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final members = await OrganizationsApi(dio).listMembers('org-1');

      expect(adapter.lastRequest!.path, '/organizations/org-1/members');
      expect(adapter.lastRequest!.method, 'GET');
      expect(members, hasLength(1));
      expect(members.single.membershipId, 'membership-1');
      expect(members.single.user.displayName, 'Ada Lovelace');
      expect(members.single.user.email, 'ada@example.com');
      expect(members.single.role.name, 'Owner');
    });

    test('parses an empty members list truthfully', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody({'success': true, 'data': {'members': []}}, 200));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final members = await OrganizationsApi(dio).listMembers('org-1');

      expect(members, isEmpty);
    });
  });

  group('listRoles() (Product Task 052)', () {
    test('hits the organization-scoped roles path and parses embedded permissions exactly', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'roles': [
              {
                'id': 'role-1',
                'name': 'Owner',
                'description': 'Full access',
                'permissions': [
                  {'id': 'perm-1', 'name': 'people.view'},
                ],
              },
            ],
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final roles = await OrganizationsApi(dio).listRoles('org-1');

      expect(adapter.lastRequest!.path, '/organizations/org-1/roles');
      expect(adapter.lastRequest!.method, 'GET');
      expect(roles, hasLength(1));
      expect(roles.single.name, 'Owner');
      expect(roles.single.description, 'Full access');
      expect(roles.single.permissions, hasLength(1));
      expect(roles.single.permissions.single.name, 'people.view');
    });

    test('parses a role with a truthfully empty permissions list, never fabricated', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'roles': [
              {'id': 'role-1', 'name': 'Member', 'description': null, 'permissions': []},
            ],
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final roles = await OrganizationsApi(dio).listRoles('org-1');

      expect(roles.single.description, isNull);
      expect(roles.single.permissions, isEmpty);
    });

    test('parses an empty roles list truthfully', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody({'success': true, 'data': {'roles': []}}, 200));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final roles = await OrganizationsApi(dio).listRoles('org-1');

      expect(roles, isEmpty);
    });
  });

  group('listPermissions() (Product Task 052)', () {
    test('hits the organization-scoped permissions path and parses each permission exactly', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'permissions': [
              {'id': 'perm-1', 'name': 'people.view'},
            ],
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final permissions = await OrganizationsApi(dio).listPermissions('org-1');

      expect(adapter.lastRequest!.path, '/organizations/org-1/permissions');
      expect(adapter.lastRequest!.method, 'GET');
      expect(permissions.single.id, 'perm-1');
      expect(permissions.single.name, 'people.view');
    });

    test('parses an empty permissions list truthfully, never fabricating a permission', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({'success': true, 'data': {'permissions': []}}, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final permissions = await OrganizationsApi(dio).listPermissions('org-1');

      expect(permissions, isEmpty);
    });
  });
}
