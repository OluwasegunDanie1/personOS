import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/features/notifications/notifications_api.dart';

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

ResponseBody _ok(Map<String, dynamic> data) => ResponseBody.fromString(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  group('list()', () {
    test('calls the exact organization-scoped route and parses the exact approved fields', () async {
      final adapter = _FakeAdapter(
        (options) async => _ok({
          'notifications': [
            {
              'id': 'notif-1',
              'title': 'New follow-up assigned',
              'message': 'You have a new follow-up due soon.',
              'isRead': false,
              'createdAt': '2026-07-14T09:00:00.000Z',
            },
          ],
          'nextCursor': null,
        }),
      );
      final api = NotificationsApi(_dioWith(adapter));

      final result = await api.list(organizationId: 'org-1');

      expect(adapter.lastRequest!.path, '/organizations/org-1/notifications');
      expect(result.notifications, hasLength(1));
      expect(result.notifications.single.id, 'notif-1');
      expect(result.notifications.single.isRead, isFalse);
      expect(result.nextCursor, isNull);
    });

    test('sends cursor, limit, and read as query parameters', () async {
      final adapter = _FakeAdapter((options) async => _ok({'notifications': [], 'nextCursor': null}));
      final api = NotificationsApi(_dioWith(adapter));

      await api.list(organizationId: 'org-1', cursor: 'abc', limit: 10, read: false);

      expect(adapter.lastRequest!.queryParameters['cursor'], 'abc');
      expect(adapter.lastRequest!.queryParameters['limit'], 10);
      expect(adapter.lastRequest!.queryParameters['read'], 'false');
    });

    test('omits query params entirely when not supplied', () async {
      final adapter = _FakeAdapter((options) async => _ok({'notifications': [], 'nextCursor': null}));
      final api = NotificationsApi(_dioWith(adapter));

      await api.list(organizationId: 'org-1');

      expect(adapter.lastRequest!.queryParameters.containsKey('cursor'), isFalse);
      expect(adapter.lastRequest!.queryParameters.containsKey('read'), isFalse);
    });

    test('returns a usable nextCursor for pagination', () async {
      final adapter = _FakeAdapter(
        (options) async => _ok({
          'notifications': [
            {
              'id': 'notif-1',
              'title': 'Title',
              'message': 'Message',
              'isRead': false,
              'createdAt': '2026-07-14T09:00:00.000Z',
            },
          ],
          'nextCursor': 'opaque-cursor',
        }),
      );
      final api = NotificationsApi(_dioWith(adapter));

      final result = await api.list(organizationId: 'org-1');

      expect(result.nextCursor, 'opaque-cursor');
    });
  });

  group('markRead()', () {
    test('calls the exact mark-read route and parses the updated notification', () async {
      final adapter = _FakeAdapter(
        (options) async => _ok({
          'notification': {
            'id': 'notif-1',
            'title': 'Title',
            'message': 'Message',
            'isRead': true,
            'createdAt': '2026-07-14T09:00:00.000Z',
          },
        }),
      );
      final api = NotificationsApi(_dioWith(adapter));

      final notification = await api.markRead(organizationId: 'org-1', notificationId: 'notif-1');

      expect(adapter.lastRequest!.path, '/organizations/org-1/notifications/notif-1/read');
      expect(adapter.lastRequest!.method, 'PATCH');
      expect(notification.isRead, isTrue);
    });
  });

  group('markAllRead()', () {
    test('calls the exact mark-all-read route and returns the real markedCount', () async {
      final adapter = _FakeAdapter((options) async => _ok({'markedCount': 4}));
      final api = NotificationsApi(_dioWith(adapter));

      final markedCount = await api.markAllRead(organizationId: 'org-1');

      expect(adapter.lastRequest!.path, '/organizations/org-1/notifications/read-all');
      expect(adapter.lastRequest!.method, 'PATCH');
      expect(markedCount, 4);
    });
  });

  group('clearRead()', () {
    test('calls the exact clear-read route and returns the real clearedCount', () async {
      final adapter = _FakeAdapter((options) async => _ok({'clearedCount': 2}));
      final api = NotificationsApi(_dioWith(adapter));

      final clearedCount = await api.clearRead(organizationId: 'org-1');

      expect(adapter.lastRequest!.path, '/organizations/org-1/notifications/read');
      expect(adapter.lastRequest!.method, 'DELETE');
      expect(clearedCount, 2);
    });
  });
}
