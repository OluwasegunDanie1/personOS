import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/features/events/events_api.dart';
import 'package:relvio/features/people/people_models.dart' show FieldUpdate;

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

Dio _dioWith(_FakeAdapter adapter) => Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

ResponseBody _ok(Map<String, dynamic> data, {int status = 200}) => ResponseBody.fromString(
  jsonEncode({'success': true, 'data': data}),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

Map<String, dynamic> _eventJson({
  String id = 'event-1',
  String title = 'Sunday Service',
  String? cancelledAt,
  String? endDate,
}) => {
  'id': id,
  'title': title,
  'description': null,
  'category': null,
  'venue': null,
  'startDate': '2026-08-02T09:00:00.000Z',
  'endDate': endDate,
  'cancelledAt': cancelledAt,
  'createdAt': '2026-01-01T00:00:00.000Z',
};

Map<String, dynamic> _eventDetailJson({String? cancelledAt}) => {
  ..._eventJson(cancelledAt: cancelledAt),
  'createdBy': {'id': 'user-1', 'firstName': 'Ada', 'lastName': 'Lovelace'},
};

void main() {
  group('list()', () {
    test('sends search and category as query parameters', () async {
      final adapter = _FakeAdapter(
        (options) async => _ok({
          'events': [_eventJson()],
          'nextCursor': null,
        }),
      );
      final api = EventsApi(_dioWith(adapter));

      final result = await api.list(organizationId: 'org-1', search: 'sunday', category: 'Worship');

      expect(adapter.lastRequest!.path, '/organizations/org-1/events');
      expect(adapter.lastRequest!.queryParameters['search'], 'sunday');
      expect(adapter.lastRequest!.queryParameters['category'], 'Worship');
      expect(result.events, hasLength(1));
      expect(result.events.single.cancelledAt, isNull);
    });

    test('omits search/category query params when empty', () async {
      final adapter = _FakeAdapter((options) async => _ok({'events': [], 'nextCursor': null}));
      final api = EventsApi(_dioWith(adapter));

      await api.list(organizationId: 'org-1', search: '', category: '');

      expect(adapter.lastRequest!.queryParameters.containsKey('search'), isFalse);
      expect(adapter.lastRequest!.queryParameters.containsKey('category'), isFalse);
    });

    test('parses a cancelled event within the list', () async {
      final adapter = _FakeAdapter(
        (options) async => _ok({
          'events': [_eventJson(cancelledAt: '2026-07-10T08:00:00.000Z')],
          'nextCursor': null,
        }),
      );
      final api = EventsApi(_dioWith(adapter));

      final result = await api.list(organizationId: 'org-1');

      expect(result.events.single.cancelledAt, DateTime.parse('2026-07-10T08:00:00.000Z'));
    });
  });

  group('create()', () {
    test('serializes startDate/endDate as UTC ISO 8601 absolute instants', () async {
      final adapter = _FakeAdapter((options) async => _ok({'event': _eventDetailJson()}));
      final api = EventsApi(_dioWith(adapter));

      final localStart = DateTime(2026, 8, 2, 9, 0);
      final localEnd = DateTime(2026, 8, 2, 11, 0);

      await api.create(organizationId: 'org-1', title: 'Sunday Service', startDate: localStart, endDate: localEnd);

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['startDate'], localStart.toUtc().toIso8601String());
      expect(body['endDate'], localEnd.toUtc().toIso8601String());
    });

    test('omits endDate entirely when not supplied (never defaults it)', () async {
      final adapter = _FakeAdapter((options) async => _ok({'event': _eventDetailJson()}));
      final api = EventsApi(_dioWith(adapter));

      await api.create(organizationId: 'org-1', title: 'Sunday Service', startDate: DateTime(2026, 8, 2, 9, 0));

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('endDate'), isFalse);
    });

    test('trims and omits blank optional fields', () async {
      final adapter = _FakeAdapter((options) async => _ok({'event': _eventDetailJson()}));
      final api = EventsApi(_dioWith(adapter));

      await api.create(
        organizationId: 'org-1',
        title: '  Sunday Service  ',
        category: '   ',
        venue: '  ',
        startDate: DateTime(2026, 8, 2, 9, 0),
      );

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['title'], 'Sunday Service');
      expect(body.containsKey('category'), isFalse);
      expect(body.containsKey('venue'), isFalse);
    });
  });

  group('update()', () {
    test('every parameter defaults to omit, so an unmentioned field never enters the body', () async {
      final adapter = _FakeAdapter((options) async => _ok({'event': _eventDetailJson()}));
      final api = EventsApi(_dioWith(adapter));

      await api.update(organizationId: 'org-1', eventId: 'event-1', title: const FieldUpdate.value('New title'));

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body, {'title': 'New title'});
    });

    test('FieldUpdate.clear always serializes JSON null for nullable fields', () async {
      final adapter = _FakeAdapter((options) async => _ok({'event': _eventDetailJson()}));
      final api = EventsApi(_dioWith(adapter));

      await api.update(organizationId: 'org-1', eventId: 'event-1', category: const FieldUpdate.clear());

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body.containsKey('category'), isTrue);
      expect(body['category'], isNull);
    });

    test('startDate/endDate FieldUpdate values are serialized as UTC ISO 8601', () async {
      final adapter = _FakeAdapter((options) async => _ok({'event': _eventDetailJson()}));
      final api = EventsApi(_dioWith(adapter));

      final newStart = DateTime(2026, 9, 1, 10, 0);
      await api.update(organizationId: 'org-1', eventId: 'event-1', startDate: FieldUpdate.value(newStart));

      final body = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(body['startDate'], newStart.toUtc().toIso8601String());
    });
  });

  group('cancel()', () {
    test('calls the cancel route and parses the returned cancelledAt', () async {
      final adapter = _FakeAdapter(
        (options) async => _ok({'event': _eventDetailJson(cancelledAt: '2026-07-14T10:00:00.000Z')}),
      );
      final api = EventsApi(_dioWith(adapter));

      final detail = await api.cancel(organizationId: 'org-1', eventId: 'event-1');

      expect(adapter.lastRequest!.path, '/organizations/org-1/events/event-1/cancel');
      expect(adapter.lastRequest!.method, 'POST');
      expect(detail.cancelledAt, DateTime.parse('2026-07-14T10:00:00.000Z'));
    });
  });

  group('attendance()', () {
    test('calls the real read-only attendance route and parses real records', () async {
      final adapter = _FakeAdapter(
        (options) async => _ok({
          'attendance': [
            {
              'id': 'att-1',
              'person': {'id': 'person-1', 'firstName': 'Grace', 'lastName': 'Hopper'},
              'status': 'PRESENT',
              'checkedInBy': {'id': 'user-1', 'firstName': 'Ada', 'lastName': 'Lovelace'},
              'checkedInAt': '2026-08-02T09:05:00.000Z',
            },
          ],
          'nextCursor': null,
        }),
      );
      final api = EventsApi(_dioWith(adapter));

      final result = await api.attendance(organizationId: 'org-1', eventId: 'event-1');

      expect(adapter.lastRequest!.path, '/organizations/org-1/events/event-1/attendance');
      expect(result.attendance, hasLength(1));
      expect(result.attendance.single.personDisplayName, 'Grace Hopper');
      expect(result.attendance.single.status, 'PRESENT');
    });
  });
}
