import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/events/event_attendance_screen.dart';
import 'package:relvio/features/events/event_models.dart';
import 'package:relvio/features/events/events_api.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';

typedef _AttendanceHandler = Future<EventAttendanceListResult> Function(String eventId);

class _ScriptedEventsApi extends EventsApi {
  _ScriptedEventsApi({required this.attendanceHandler}) : super(Dio());

  _AttendanceHandler attendanceHandler;

  @override
  Future<EventAttendanceListResult> attendance({
    required String organizationId,
    required String eventId,
    String? cursor,
  }) => attendanceHandler(eventId);
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

Future<void> _pumpAttendanceScreen(WidgetTester tester, {required _AttendanceHandler attendanceHandler}) async {
  final api = _ScriptedEventsApi(attendanceHandler: attendanceHandler);

  final router = GoRouter(
    initialLocation: '/events/event-1/attendance',
    routes: [
      GoRoute(
        path: '/events/:eventId/attendance',
        builder: (context, state) => EventAttendanceScreen(eventId: state.pathParameters['eventId']!),
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
}

void main() {
  testWidgets('renders real checked-in Attendance records: name, status, checked-in time', (
    WidgetTester tester,
  ) async {
    await _pumpAttendanceScreen(
      tester,
      attendanceHandler: (eventId) async => EventAttendanceListResult(
        attendance: [
          EventAttendanceRecord(
            id: 'att-1',
            personId: 'person-1',
            personFirstName: 'Grace',
            personLastName: 'Hopper',
            status: 'PRESENT',
            checkedInAt: DateTime.utc(2026, 8, 2, 9, 5),
          ),
        ],
        nextCursor: null,
      ),
    );

    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('PRESENT'), findsOneWidget);
  });

  testWidgets('a truthful empty state is shown when no attendance has been recorded', (WidgetTester tester) async {
    await _pumpAttendanceScreen(
      tester,
      attendanceHandler: (eventId) async => const EventAttendanceListResult(attendance: [], nextCursor: null),
    );

    expect(find.text('No attendance has been recorded for this event yet.'), findsOneWidget);
  });

  testWidgets('no RSVP/registration/guest wording exists anywhere', (WidgetTester tester) async {
    await _pumpAttendanceScreen(
      tester,
      attendanceHandler: (eventId) async => EventAttendanceListResult(
        attendance: [
          EventAttendanceRecord(
            id: 'att-1',
            personId: 'person-1',
            personFirstName: 'Grace',
            personLastName: 'Hopper',
            status: 'PRESENT',
            checkedInAt: DateTime.utc(2026, 8, 2, 9, 5),
          ),
        ],
        nextCursor: null,
      ),
    );

    expect(find.textContaining('RSVP'), findsNothing);
    expect(find.textContaining('Registered'), findsNothing);
    expect(find.textContaining('Guest'), findsNothing);
  });

  testWidgets('an honest "more exist" note is shown instead of a fabricated total when hasMore', (
    WidgetTester tester,
  ) async {
    await _pumpAttendanceScreen(
      tester,
      attendanceHandler: (eventId) async => EventAttendanceListResult(
        attendance: [
          EventAttendanceRecord(
            id: 'att-1',
            personId: 'person-1',
            personFirstName: 'Grace',
            personLastName: 'Hopper',
            status: 'PRESENT',
            checkedInAt: DateTime.utc(2026, 8, 2, 9, 5),
          ),
        ],
        nextCursor: 'opaque-cursor',
      ),
    );

    expect(find.text('More attendance records exist for this event.'), findsOneWidget);
  });

  testWidgets('a truthful, retryable error state is shown on load failure', (WidgetTester tester) async {
    await _pumpAttendanceScreen(tester, attendanceHandler: (eventId) async => throw Exception('network down'));

    expect(find.text('Could not load attendance.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });
}
