import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/features/dashboard/dashboard_api.dart';

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

void main() {
  test('fetch() calls the organization-scoped dashboard path and parses the exact approved fields', () async {
    final adapter = _FakeAdapter(
      (options) async => ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {
            'totalPeople': 120,
            'newPeople': 5,
            'pendingFollowUps': 3,
            'upcomingEvents': [
              {'id': 'event-1', 'title': 'Sunday Service', 'startDate': '2026-07-19T09:00:00.000Z'},
            ],
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      ),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://relvio.test'))..httpClientAdapter = adapter;

    final summary = await DashboardApi(dio).fetch('org-1');

    expect(adapter.lastRequest!.path, '/organizations/org-1/reports/dashboard');
    expect(summary.totalPeople, 120);
    expect(summary.newPeople, 5);
    expect(summary.pendingFollowUps, 3);
    expect(summary.upcomingEvents, hasLength(1));
    expect(summary.upcomingEvents.single.id, 'event-1');
    expect(summary.upcomingEvents.single.title, 'Sunday Service');
  });
}
