import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/events/event_detail_screen.dart';
import 'package:relvio/features/events/event_models.dart';
import 'package:relvio/features/events/events_api.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';

typedef _DetailHandler = Future<EventDetail> Function(String eventId);

class _ScriptedEventsApi extends EventsApi {
  _ScriptedEventsApi({required this.detailHandler}) : super(Dio());

  _DetailHandler detailHandler;

  @override
  Future<EventDetail> detail({required String organizationId, required String eventId}) => detailHandler(eventId);
}

class _FakeOrganizationContextController extends OrganizationContextController {
  _FakeOrganizationContextController(this._state);
  final OrganizationContextState _state;
  @override
  OrganizationContextState build() => _state;
}

const _orgA = OrganizationContextActive(
  organizations: [
    OrganizationSummary(id: 'org-1', name: 'org-1', logoUrl: null, role: OrganizationRole(id: 'r', name: 'Owner')),
  ],
  selectedOrganizationId: 'org-1',
);

EventDetail _detail({
  String title = 'Sunday Service',
  String? description,
  String? venue,
  DateTime? cancelledAt,
}) => EventDetail(
  id: 'event-1',
  title: title,
  description: description,
  category: null,
  venue: venue,
  startDate: DateTime.utc(2026, 8, 2, 9, 0),
  endDate: DateTime.utc(2026, 8, 2, 11, 0),
  cancelledAt: cancelledAt,
  createdAt: DateTime.now().toUtc(),
  createdBy: const EventCreatorRef(id: 'user-1', firstName: 'Ada', lastName: 'Lovelace'),
);

Future<GoRouter> _pumpEventDetailScreen(WidgetTester tester, {required _DetailHandler detailHandler}) async {
  final api = _ScriptedEventsApi(detailHandler: detailHandler);

  final router = GoRouter(
    initialLocation: '/events/event-1',
    routes: [
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) => EventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/:eventId/edit',
        builder: (context, state) => Scaffold(body: Text('Edit ${state.pathParameters['eventId']}')),
      ),
      GoRoute(
        path: '/events/:eventId/attendance',
        builder: (context, state) => Scaffold(body: Text('Attendance ${state.pathParameters['eventId']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventsApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => _FakeOrganizationContextController(_orgA)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return router;
}

void main() {
  testWidgets('renders real truthful fields: title, date/time, venue, description, createdBy', (
    WidgetTester tester,
  ) async {
    await _pumpEventDetailScreen(
      tester,
      detailHandler: (eventId) async => _detail(description: 'Weekly worship service', venue: 'Main Auditorium'),
    );

    expect(find.text('Sunday Service'), findsOneWidget);
    expect(find.text('Weekly worship service'), findsOneWidget);
    expect(find.text('Main Auditorium'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('unsupported sections are absent: stats grid, Attendance Summary, Registered People, Announcements, Notes, Recent Activity, Start Check-In', (
    WidgetTester tester,
  ) async {
    await _pumpEventDetailScreen(tester, detailHandler: (eventId) async => _detail());

    expect(find.text('Expected'), findsNothing);
    expect(find.text('Checked In'), findsNothing);
    expect(find.text('Pending'), findsNothing);
    expect(find.text('Guests'), findsNothing);
    expect(find.text('Attendance Summary'), findsNothing);
    expect(find.text('Registered People'), findsNothing);
    expect(find.text('Announcements'), findsNothing);
    expect(find.text('Notes'), findsNothing);
    expect(find.text('Recent Activity'), findsNothing);
    expect(find.text('Start Check-In'), findsNothing);
    expect(find.text('Share'), findsNothing);
  });

  testWidgets('Edit navigates to the real Edit Event route', (WidgetTester tester) async {
    final router = await _pumpEventDetailScreen(tester, detailHandler: (eventId) async => _detail());

    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/events/event-1/edit');
  });

  testWidgets('Attendance navigates to the real read-only Attendance list route', (WidgetTester tester) async {
    final router = await _pumpEventDetailScreen(tester, detailHandler: (eventId) async => _detail());

    await tester.tap(find.text('Attendance'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/events/event-1/attendance');
  });

  testWidgets('a cancelled event shows the Cancelled badge, not Upcoming/Today/Completed', (
    WidgetTester tester,
  ) async {
    await _pumpEventDetailScreen(
      tester,
      detailHandler: (eventId) async => _detail(cancelledAt: DateTime.utc(2026, 7, 1)),
    );

    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('a truthful, retryable error state is shown on load failure', (WidgetTester tester) async {
    await _pumpEventDetailScreen(tester, detailHandler: (eventId) async => throw Exception('network down'));

    expect(find.text('Could not load this event.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });
}
