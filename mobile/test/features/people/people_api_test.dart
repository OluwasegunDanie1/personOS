import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';

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
  group('PersonSummary parsing', () {
    test('parses a fully-populated ACTIVE person', () {
      final person = PersonSummary.fromJson({
        'id': 'p1',
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': 'ada@example.com',
        'phone': '+1234567890',
        'status': 'ACTIVE',
        'avatarUrl': 'https://example.com/ada.png',
        'joinedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(person.status, PersonStatus.active);
      expect(person.displayName, 'Ada Lovelace');
      expect(person.initials, 'AL');
      expect(person.avatarUrl, 'https://example.com/ada.png');
    });

    test('parses INACTIVE status and nullable email/phone/avatarUrl', () {
      final person = PersonSummary.fromJson({
        'id': 'p2',
        'firstName': 'Grace',
        'lastName': 'Hopper',
        'email': null,
        'phone': null,
        'status': 'INACTIVE',
        'avatarUrl': null,
        'joinedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(person.status, PersonStatus.inactive);
      expect(person.email, isNull);
      expect(person.phone, isNull);
      expect(person.avatarUrl, isNull);
    });

    test('initials omit a missing name part rather than inventing a placeholder', () {
      final person = PersonSummary.fromJson({
        'id': 'p3',
        'firstName': '',
        'lastName': 'Turing',
        'email': null,
        'phone': null,
        'status': 'ACTIVE',
        'avatarUrl': null,
        'joinedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(person.initials, 'T');
    });
  });

  group('PeoplePage parsing', () {
    test('parses a populated page with a non-null nextCursor', () {
      final page = PeoplePage.fromJson({
        'people': [
          {
            'id': 'p1',
            'firstName': 'Ada',
            'lastName': 'Lovelace',
            'email': null,
            'phone': null,
            'status': 'ACTIVE',
            'avatarUrl': null,
            'joinedAt': '2026-01-01T00:00:00.000Z',
          },
        ],
        'nextCursor': 'opaque-cursor',
      });

      expect(page.people, hasLength(1));
      expect(page.nextCursor, 'opaque-cursor');
    });

    test('parses an empty page with a null nextCursor', () {
      final page = PeoplePage.fromJson({'people': [], 'nextCursor': null});

      expect(page.people, isEmpty);
      expect(page.nextCursor, isNull);
    });
  });

  group('PeopleApi.list request construction', () {
    test('omits search and status query parameters when not supplied', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {'people': [], 'nextCursor': null},
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).list(organizationId: 'org-1');

      expect(adapter.lastRequest!.path, '/organizations/org-1/people');
      expect(adapter.lastRequest!.uri.queryParameters.containsKey('search'), isFalse);
      expect(adapter.lastRequest!.uri.queryParameters.containsKey('status'), isFalse);
      expect(adapter.lastRequest!.uri.queryParameters.containsKey('cursor'), isFalse);
    });

    test('sends the search query parameter when supplied', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {'people': [], 'nextCursor': null},
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).list(organizationId: 'org-1', search: 'john');

      expect(adapter.lastRequest!.uri.queryParameters['search'], 'john');
    });

    test('sends status=ACTIVE for the active filter', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {'people': [], 'nextCursor': null},
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).list(organizationId: 'org-1', status: PersonStatus.active);

      expect(adapter.lastRequest!.uri.queryParameters['status'], 'ACTIVE');
    });

    test('sends status=INACTIVE for the inactive filter', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {'people': [], 'nextCursor': null},
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).list(organizationId: 'org-1', status: PersonStatus.inactive);

      expect(adapter.lastRequest!.uri.queryParameters['status'], 'INACTIVE');
    });

    test('forwards the cursor unchanged', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {'people': [], 'nextCursor': null},
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).list(organizationId: 'org-1', cursor: 'opaque-cursor-value');

      expect(adapter.lastRequest!.uri.queryParameters['cursor'], 'opaque-cursor-value');
    });

    test('parses the response through the existing envelope authority', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'people': [
              {
                'id': 'p1',
                'firstName': 'Ada',
                'lastName': 'Lovelace',
                'email': null,
                'phone': null,
                'status': 'ACTIVE',
                'avatarUrl': null,
                'joinedAt': '2026-01-01T00:00:00.000Z',
              },
            ],
            'nextCursor': null,
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final page = await PeopleApi(dio).list(organizationId: 'org-1');

      expect(page.people.single.id, 'p1');
      expect(page.nextCursor, isNull);
    });
  });
}
