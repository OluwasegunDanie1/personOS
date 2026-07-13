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

    Map<String, dynamic> baseJson({Object? currentJourneyStage, Object? lastAttendance}) => {
      'id': 'p1',
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'email': null,
      'phone': null,
      'status': 'ACTIVE',
      'avatarUrl': null,
      'joinedAt': '2026-01-01T00:00:00.000Z',
      'currentJourneyStage': currentJourneyStage,
      'lastAttendance': lastAttendance,
    };

    test('currentJourneyStage is null when the key is absent', () {
      final json = baseJson()..remove('currentJourneyStage');

      final person = PersonSummary.fromJson(json);

      expect(person.currentJourneyStage, isNull);
    });

    test('currentJourneyStage is null when explicitly null', () {
      final person = PersonSummary.fromJson(baseJson(currentJourneyStage: null));

      expect(person.currentJourneyStage, isNull);
    });

    test('currentJourneyStage parses exact id and name', () {
      final person = PersonSummary.fromJson(
        baseJson(currentJourneyStage: {'id': 'stage-1', 'name': 'Connected Guest'}),
      );

      expect(person.currentJourneyStage?.id, 'stage-1');
      expect(person.currentJourneyStage?.name, 'Connected Guest');
    });

    test('an organization-configured stage name is preserved exactly, unmodified', () {
      const rawName = 'somos FAMILIA — etapa 3';
      final person = PersonSummary.fromJson(
        baseJson(currentJourneyStage: {'id': 'stage-1', 'name': rawName}),
      );

      expect(person.currentJourneyStage?.name, rawName);
    });

    test('lastAttendance is null when the key is absent', () {
      final json = baseJson()..remove('lastAttendance');

      final person = PersonSummary.fromJson(json);

      expect(person.lastAttendance, isNull);
    });

    test('lastAttendance is null when explicitly null', () {
      final person = PersonSummary.fromJson(baseJson(lastAttendance: null));

      expect(person.lastAttendance, isNull);
    });

    test('lastAttendance parses checkedInAt as a DateTime', () {
      final person = PersonSummary.fromJson(
        baseJson(lastAttendance: {'checkedInAt': '2026-05-25T09:00:00.000Z'}),
      );

      expect(person.lastAttendance?.checkedInAt, DateTime.parse('2026-05-25T09:00:00.000Z'));
    });

    test('a Create-response-shaped payload without either new field still parses successfully', () {
      final person = PersonSummary.fromJson({
        'id': 'p1',
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'email': null,
        'phone': null,
        'status': 'ACTIVE',
        'avatarUrl': null,
        'joinedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(person.currentJourneyStage, isNull);
      expect(person.lastAttendance, isNull);
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

  group('PeopleApi.create request construction', () {
    Map<String, dynamic> personResponse({String status = 'ACTIVE'}) => {
      'success': true,
      'data': {
        'person': {
          'id': 'p1',
          'firstName': 'Ada',
          'lastName': 'Lovelace',
          'email': null,
          'phone': null,
          'status': status,
          'avatarUrl': null,
          'joinedAt': '2026-01-01T00:00:00.000Z',
        },
      },
    };

    test('posts to the organization-scoped People endpoint', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', status: PersonStatus.active);

      expect(adapter.lastRequest!.path, '/organizations/org-1/people');
      expect(adapter.lastRequest!.method, 'POST');
    });

    test('trims firstName and lastName', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: '  Ada  ', lastName: '  Lovelace  ', status: PersonStatus.active);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['firstName'], 'Ada');
      expect(body['lastName'], 'Lovelace');
    });

    test('omits empty email', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', email: '', status: PersonStatus.active);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('email'), isFalse);
    });

    test('omits whitespace-only email', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).create(
        organizationId: 'org-1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: '   ',
        status: PersonStatus.active,
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('email'), isFalse);
    });

    test('trims and lowercases a non-empty email', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).create(
        organizationId: 'org-1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: '  ADA@Example.COM  ',
        status: PersonStatus.active,
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['email'], 'ada@example.com');
    });

    test('omits empty phone', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', phone: '', status: PersonStatus.active);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('phone'), isFalse);
    });

    test('omits whitespace-only phone', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).create(
        organizationId: 'org-1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        phone: '   ',
        status: PersonStatus.active,
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('phone'), isFalse);
    });

    test('trims a non-empty phone', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).create(
        organizationId: 'org-1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        phone: '  +1 234 567  ',
        status: PersonStatus.active,
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['phone'], '+1 234 567');
    });

    test('serializes Active as ACTIVE', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', status: PersonStatus.active);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['status'], 'ACTIVE');
    });

    test('serializes Inactive as INACTIVE', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(status: 'INACTIVE'), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', status: PersonStatus.inactive);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['status'], 'INACTIVE');
    });

    test('never serializes unsupported fields', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', status: PersonStatus.active);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.keys, {'firstName', 'lastName', 'status'});
    });

    test('parses the returned PersonSummary through the existing envelope authority', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final person = await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', status: PersonStatus.active);

      expect(person.id, 'p1');
      expect(person.status, PersonStatus.active);
    });

    test('surfaces a mapped backend error through the existing error authority', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': false,
          'error': {'code': 'VALIDATION_ERROR', 'message': 'Invalid request.'},
        }, 422),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await expectLater(
        PeopleApi(dio).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', status: PersonStatus.active),
        throwsA(isA<Exception>()),
      );
    });

    test('gender omitted is not serialized', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', status: PersonStatus.active);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('gender'), isFalse);
    });

    test('Male selection serializes MALE', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).create(
        organizationId: 'org-1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        status: PersonStatus.active,
        gender: PersonGender.male,
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['gender'], 'MALE');
    });

    test('Female selection serializes FEMALE', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).create(
        organizationId: 'org-1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        status: PersonStatus.active,
        gender: PersonGender.female,
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['gender'], 'FEMALE');
    });

    test('dateOfBirth omitted is not serialized', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', status: PersonStatus.active);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('dateOfBirth'), isFalse);
    });

    test('selected DOB serializes exact YYYY-MM-DD with no time/offset component', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).create(
        organizationId: 'org-1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        status: PersonStatus.active,
        dateOfBirth: DateTime(2001, 7, 14),
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['dateOfBirth'], '2001-07-14');
      expect(body['dateOfBirth'], isNot(contains('T')));
      expect(body['dateOfBirth'], isNot(contains('Z')));
      expect(body['dateOfBirth'], isNot(contains('+')));
    });

    test('address omitted is not serialized', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', status: PersonStatus.active);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('address'), isFalse);
    });

    test('whitespace-only address is omitted', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).create(
        organizationId: 'org-1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        status: PersonStatus.active,
        address: '   ',
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('address'), isFalse);
    });

    test('non-empty address is trimmed', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(dio).create(
        organizationId: 'org-1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        status: PersonStatus.active,
        address: '  123 Main St  ',
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['address'], '123 Main St');
    });

    test('gender/dateOfBirth/address absent when unsupplied, and all other fields still exact', () async {
      final adapter = _FakeAdapter((options) async => _jsonBody(personResponse(), 201));
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await PeopleApi(
        dio,
      ).create(organizationId: 'org-1', firstName: 'Ada', lastName: 'Lovelace', status: PersonStatus.active);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.keys, {'firstName', 'lastName', 'status'});
    });
  });

  group('PersonDetail parsing (Product Task 041)', () {
    Map<String, dynamic> detailPersonJson({Map<String, dynamic> overrides = const {}}) => {
      'id': 'p1',
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'email': 'ada@example.com',
      'phone': '+1234567890',
      'status': 'ACTIVE',
      'avatarUrl': null,
      'joinedAt': '2026-01-01T00:00:00.000Z',
      'tags': [
        {'id': 'tag-1', 'name': 'VIP'},
      ],
      'currentJourneyStage': {'id': 'stage-1', 'name': 'Visitor'},
      'gender': 'FEMALE',
      'dateOfBirth': '1990-12-31',
      'address': '221B Baker Street',
      ...overrides,
    };

    test('parses every field of a fully-populated Person Detail response', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {'person': detailPersonJson()},
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final person = await PeopleApi(dio).detail(organizationId: 'org-1', personId: 'p1');

      expect(person.id, 'p1');
      expect(person.displayName, 'Ada Lovelace');
      expect(person.email, 'ada@example.com');
      expect(person.phone, '+1234567890');
      expect(person.status, PersonStatus.active);
      expect(person.avatarUrl, isNull);
      expect(person.joinedAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(person.tags, hasLength(1));
      expect(person.tags.single.id, 'tag-1');
      expect(person.tags.single.name, 'VIP');
      expect(person.currentJourneyStage!.id, 'stage-1');
      expect(person.currentJourneyStage!.name, 'Visitor');
      expect(person.gender, PersonGender.female);
      expect(person.address, '221B Baker Street');
      expect(adapter.lastRequest!.path, '/organizations/org-1/people/p1');
    });

    test('preserves nullable gender/dateOfBirth/address/currentJourneyStage/avatarUrl as null', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'person': detailPersonJson(
              overrides: {
                'gender': null,
                'dateOfBirth': null,
                'address': null,
                'currentJourneyStage': null,
                'avatarUrl': null,
                'tags': [],
              },
            ),
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final person = await PeopleApi(dio).detail(organizationId: 'org-1', personId: 'p1');

      expect(person.gender, isNull);
      expect(person.dateOfBirth, isNull);
      expect(person.address, isNull);
      expect(person.currentJourneyStage, isNull);
      expect(person.avatarUrl, isNull);
      expect(person.tags, isEmpty);
    });

    test('preserves the exact calendar date for dateOfBirth regardless of device-local timezone', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'person': detailPersonJson(overrides: {'dateOfBirth': '1990-12-31'}),
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final person = await PeopleApi(dio).detail(organizationId: 'org-1', personId: 'p1');

      expect(person.dateOfBirth!.year, 1990);
      expect(person.dateOfBirth!.month, 12);
      expect(person.dateOfBirth!.day, 31);
      expect(person.dateOfBirth!.isUtc, isTrue, reason: 'must never be parsed as a local-time timestamp');
    });

    test('a missing required field throws (existing model parsing convention: direct "as" casts)', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'person': detailPersonJson()..remove('id'),
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await expectLater(PeopleApi(dio).detail(organizationId: 'org-1', personId: 'p1'), throwsA(isA<TypeError>()));
    });
  });

  group('PersonJourneyView parsing', () {
    test('parses a non-null currentStage with position and a non-empty history', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'currentJourneyStage': {'id': 'stage-2', 'name': 'First Visit', 'position': 2},
            'history': [
              {
                'id': 'h1',
                'fromStage': {'id': 'stage-1', 'name': 'Visitor'},
                'toStage': {'id': 'stage-2', 'name': 'First Visit'},
                'note': null,
                'movedAt': '2026-04-12T10:00:00.000Z',
                'movedBy': {'id': 'user-1', 'firstName': 'Grace', 'lastName': 'Hopper'},
              },
            ],
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final journey = await PeopleApi(dio).journey(organizationId: 'org-1', personId: 'p1');

      expect(journey.currentStage!.id, 'stage-2');
      expect(journey.currentStage!.name, 'First Visit');
      expect(journey.currentStage!.position, 2);
      expect(journey.history, hasLength(1));
      expect(journey.history.single.toStageId, 'stage-2');
      expect(journey.history.single.movedAt, DateTime.parse('2026-04-12T10:00:00.000Z'));
      expect(adapter.lastRequest!.path, '/organizations/org-1/people/p1/journey');
    });

    test('a null currentJourneyStage and empty history parse without error', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {'currentJourneyStage': null, 'history': []},
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final journey = await PeopleApi(dio).journey(organizationId: 'org-1', personId: 'p1');

      expect(journey.currentStage, isNull);
      expect(journey.history, isEmpty);
    });

    test('a missing required history field throws', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {'currentJourneyStage': null, 'history': null},
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await expectLater(
        PeopleApi(dio).journey(organizationId: 'org-1', personId: 'p1'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('JourneyStageListEntry parsing (ordered Journey Stages)', () {
    test('preserves the exact response order of a real organization-configured stage list', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'stages': [
              {'id': 's1', 'name': 'Visitor', 'position': 1},
              {'id': 's2', 'name': 'First Visit', 'position': 2},
              {'id': 's3', 'name': 'Member', 'position': 3},
            ],
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final stages = await PeopleApi(dio).journeyStages(organizationId: 'org-1');

      expect(stages.map((s) => s.name).toList(), ['Visitor', 'First Visit', 'Member']);
      expect(stages.map((s) => s.position).toList(), [1, 2, 3]);
      expect(adapter.lastRequest!.path, '/organizations/org-1/journey-stages');
    });

    test('an empty stage list parses without error (no hardcoded fallback stages)', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {'stages': []},
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final stages = await PeopleApi(dio).journeyStages(organizationId: 'org-1');

      expect(stages, isEmpty);
    });
  });

  group('AttendanceSummary parsing', () {
    test('parses totalCount and currentMonthCount exactly', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'attendanceSummary': {'totalCount': 24, 'currentMonthCount': 6},
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final summary = await PeopleApi(dio).attendanceSummary(organizationId: 'org-1', personId: 'p1');

      expect(summary.totalCount, 24);
      expect(summary.currentMonthCount, 6);
      expect(adapter.lastRequest!.path, '/organizations/org-1/people/p1/attendance/summary');
    });

    test('zero counts parse correctly (not mistaken for a missing/null field)', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'attendanceSummary': {'totalCount': 0, 'currentMonthCount': 0},
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      final summary = await PeopleApi(dio).attendanceSummary(organizationId: 'org-1', personId: 'p1');

      expect(summary.totalCount, 0);
      expect(summary.currentMonthCount, 0);
    });

    test('a missing required field throws', () async {
      final adapter = _FakeAdapter(
        (options) async => _jsonBody({
          'success': true,
          'data': {
            'attendanceSummary': {'currentMonthCount': 6},
          },
        }, 200),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

      await expectLater(
        PeopleApi(dio).attendanceSummary(organizationId: 'org-1', personId: 'p1'),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
