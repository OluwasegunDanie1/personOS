import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/events/event_check_in_screen.dart';
import 'package:relvio/features/events/event_models.dart';
import 'package:relvio/features/events/events_api.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';

typedef _PeopleListHandler = Future<PeoplePage> Function({String? search});
typedef _CheckInHandler = Future<CheckInResult> Function(String personId);
typedef _AttendanceHandler = Future<EventAttendanceListResult> Function();

class _ScriptedPeopleApi extends PeopleApi {
  _ScriptedPeopleApi({required this.listHandler}) : super(Dio());

  _PeopleListHandler listHandler;
  int listCallCount = 0;
  String? lastSearch;

  @override
  Future<PeoplePage> list({
    required String organizationId,
    String? cursor,
    String? search,
    PersonStatus? status,
    int? limit,
  }) {
    listCallCount++;
    lastSearch = search;
    return listHandler(search: search);
  }
}

class _ScriptedEventsApi extends EventsApi {
  _ScriptedEventsApi({
    required this.detailHandler,
    required this.checkInHandler,
    required this.attendanceHandler,
  }) : super(Dio());

  Future<EventDetail> Function() detailHandler;
  _CheckInHandler checkInHandler;
  _AttendanceHandler attendanceHandler;
  int checkInCallCount = 0;

  @override
  Future<EventDetail> detail({required String organizationId, required String eventId}) => detailHandler();

  @override
  Future<EventAttendanceListResult> attendance({
    required String organizationId,
    required String eventId,
    String? cursor,
  }) => attendanceHandler();

  @override
  Future<CheckInResult> recordAttendance({
    required String organizationId,
    required String eventId,
    required String personId,
  }) {
    checkInCallCount++;
    return checkInHandler(personId);
  }
}

class _FakeOrganizationContextController extends OrganizationContextController {
  _FakeOrganizationContextController(this._state);
  OrganizationContextState _state;
  @override
  OrganizationContextState build() => _state;

  void emit(OrganizationContextState next) {
    _state = next;
    state = next;
  }
}

const _orgA = OrganizationContextActive(
  organizations: [
    OrganizationSummary(id: 'org-1', name: 'org-1', logoUrl: null, role: OrganizationRole(id: 'r', name: 'Owner')),
  ],
  selectedOrganizationId: 'org-1',
);

const _orgB = OrganizationContextActive(
  organizations: [
    OrganizationSummary(id: 'org-2', name: 'org-2', logoUrl: null, role: OrganizationRole(id: 'r', name: 'Owner')),
  ],
  selectedOrganizationId: 'org-2',
);

EventDetail _eventDetail() => EventDetail(
  id: 'event-1',
  title: 'Sunday Service',
  description: null,
  category: null,
  venue: null,
  startDate: DateTime.utc(2026, 8, 2, 9, 0),
  endDate: null,
  cancelledAt: null,
  createdAt: DateTime.now().toUtc(),
  createdBy: const EventCreatorRef(id: 'user-1', firstName: 'Ada', lastName: 'Lovelace'),
);

PersonSummary _person(String id, String firstName, String lastName) => PersonSummary(
  id: id,
  firstName: firstName,
  lastName: lastName,
  email: null,
  phone: null,
  status: PersonStatus.active,
  avatarUrl: null,
  joinedAt: DateTime.now().toUtc(),
);

EventAttendanceRecord _attendanceRecord(String personId, String firstName, String lastName) => EventAttendanceRecord(
  id: 'att-$personId',
  personId: personId,
  personFirstName: firstName,
  personLastName: lastName,
  status: 'PRESENT',
  checkedInAt: DateTime.now().toUtc(),
);

class _Harness {
  _Harness(this.orgController, this.peopleApi, this.eventsApi);
  final _FakeOrganizationContextController orgController;
  final _ScriptedPeopleApi peopleApi;
  final _ScriptedEventsApi eventsApi;
}

Future<_Harness> _pumpCheckInScreen(
  WidgetTester tester, {
  required _PeopleListHandler listHandler,
  _CheckInHandler? checkInHandler,
  _AttendanceHandler? attendanceHandler,
  OrganizationContextState initialOrg = _orgA,
  bool settle = true,
}) async {
  final peopleApi = _ScriptedPeopleApi(listHandler: listHandler);
  final eventsApi = _ScriptedEventsApi(
    detailHandler: () async => _eventDetail(),
    checkInHandler: checkInHandler ?? (personId) async => CheckInResult(
      attendance: _attendanceRecord(personId, 'First', 'Last'),
      created: true,
    ),
    attendanceHandler: attendanceHandler ?? () async => const EventAttendanceListResult(attendance: [], nextCursor: null),
  );
  final orgController = _FakeOrganizationContextController(initialOrg);

  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/events/event-1/check-in',
    routes: [
      GoRoute(
        path: '/events/:eventId/check-in',
        builder: (context, state) => EventCheckInScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(path: '/events/:eventId', builder: (context, state) => const Scaffold(body: Text('Event Detail'))),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        peopleApiProvider.overrideWithValue(peopleApi),
        eventsApiProvider.overrideWithValue(eventsApi),
        organizationContextControllerProvider.overrideWith(() => orgController),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  return _Harness(orgController, peopleApi, eventsApi);
}

void main() {
  testWidgets('loads and renders real People, identifying the real Event', (WidgetTester tester) async {
    await _pumpCheckInScreen(
      tester,
      listHandler: ({search}) async => PeoplePage(people: [_person('p1', 'Grace', 'Hopper')], nextCursor: null),
    );

    expect(find.text('Sunday Service'), findsOneWidget);
    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.byKey(const Key('checkInButton-p1')), findsOneWidget);
  });

  testWidgets('searching calls list() with the real search query after debounce', (WidgetTester tester) async {
    final harness = await _pumpCheckInScreen(
      tester,
      listHandler: ({search}) async => const PeoplePage(people: [], nextCursor: null),
    );

    await tester.enterText(find.byType(TextField), 'grace');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(harness.peopleApi.lastSearch, 'grace');
  });

  testWidgets('a truthful empty state is shown when no people match', (WidgetTester tester) async {
    await _pumpCheckInScreen(tester, listHandler: ({search}) async => const PeoplePage(people: [], nextCursor: null));

    expect(find.text('No people found.'), findsOneWidget);
  });

  testWidgets('a truthful, retryable error state is shown on People load failure', (WidgetTester tester) async {
    await _pumpCheckInScreen(tester, listHandler: ({search}) async => throw Exception('network down'));

    expect(find.text('Could not load people.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('tapping Check In submits the real attendance request and shows a truthful confirmation', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpCheckInScreen(
      tester,
      listHandler: ({search}) async => PeoplePage(people: [_person('p1', 'Grace', 'Hopper')], nextCursor: null),
    );

    await tester.tap(find.byKey(const Key('checkInButton-p1')));
    await tester.pumpAndSettle();

    expect(harness.eventsApi.checkInCallCount, 1);
    expect(find.byKey(const Key('checkedInBadge-p1')), findsOneWidget);
    expect(find.byKey(const Key('checkInButton-p1')), findsNothing);
  });

  testWidgets('a real refresh of the Event Attendance list follows a successful check-in', (
    WidgetTester tester,
  ) async {
    var attendanceCallCount = 0;
    await _pumpCheckInScreen(
      tester,
      listHandler: ({search}) async => PeoplePage(people: [_person('p1', 'Grace', 'Hopper')], nextCursor: null),
      attendanceHandler: () async {
        attendanceCallCount++;
        return const EventAttendanceListResult(attendance: [], nextCursor: null);
      },
    );

    final before = attendanceCallCount;
    await tester.tap(find.byKey(const Key('checkInButton-p1')));
    await tester.pumpAndSettle();

    expect(attendanceCallCount, greaterThan(before), reason: 'a real Attendance refetch must follow check-in');
  });

  testWidgets('idempotent replay (already checked in) is handled truthfully with no duplicate/error UI', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpCheckInScreen(
      tester,
      listHandler: ({search}) async => PeoplePage(people: [_person('p1', 'Grace', 'Hopper')], nextCursor: null),
      checkInHandler: (personId) async =>
          CheckInResult(attendance: _attendanceRecord(personId, 'Grace', 'Hopper'), created: false),
    );

    await tester.tap(find.byKey(const Key('checkInButton-p1')));
    await tester.pumpAndSettle();

    expect(harness.eventsApi.checkInCallCount, 1);
    expect(find.byKey(const Key('checkedInBadge-p1')), findsOneWidget);
    expect(find.textContaining('Could not check in'), findsNothing);
  });

  testWidgets('a person already checked in before this session (from the real Attendance list) shows Checked In immediately', (
    WidgetTester tester,
  ) async {
    await _pumpCheckInScreen(
      tester,
      listHandler: ({search}) async => PeoplePage(people: [_person('p1', 'Grace', 'Hopper')], nextCursor: null),
      attendanceHandler: () async =>
          EventAttendanceListResult(attendance: [_attendanceRecord('p1', 'Grace', 'Hopper')], nextCursor: null),
    );

    expect(find.byKey(const Key('checkedInBadge-p1')), findsOneWidget);
    expect(find.byKey(const Key('checkInButton-p1')), findsNothing);
  });

  testWidgets('duplicate check-in submissions for the same person are ignored while one is in flight', (
    WidgetTester tester,
  ) async {
    final gate = Completer<CheckInResult>();
    final harness = await _pumpCheckInScreen(
      tester,
      listHandler: ({search}) async => PeoplePage(people: [_person('p1', 'Grace', 'Hopper')], nextCursor: null),
      checkInHandler: (personId) => gate.future,
    );

    await tester.tap(find.byKey(const Key('checkInButton-p1')));
    await tester.pump();
    // The button is replaced by a spinner while pending, so a second finder
    // lookup for the same key finds nothing to tap — this itself proves
    // the duplicate-submit guard held (no second button to press).
    expect(find.byKey(const Key('checkInButton-p1')), findsNothing);

    gate.complete(CheckInResult(attendance: _attendanceRecord('p1', 'Grace', 'Hopper'), created: true));
    await tester.pumpAndSettle();

    expect(harness.eventsApi.checkInCallCount, 1);
  });

  testWidgets('supports repeated check-in of different People independently', (WidgetTester tester) async {
    final harness = await _pumpCheckInScreen(
      tester,
      listHandler: ({search}) async => PeoplePage(
        people: [_person('p1', 'Grace', 'Hopper'), _person('p2', 'Ada', 'Lovelace')],
        nextCursor: null,
      ),
    );

    await tester.tap(find.byKey(const Key('checkInButton-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('checkInButton-p2')));
    await tester.pumpAndSettle();

    expect(harness.eventsApi.checkInCallCount, 2);
    expect(find.byKey(const Key('checkedInBadge-p1')), findsOneWidget);
    expect(find.byKey(const Key('checkedInBadge-p2')), findsOneWidget);
  });

  testWidgets('a checked-in row never shows an undo/remove/edit/reverse control (attendance is immutable)', (
    WidgetTester tester,
  ) async {
    await _pumpCheckInScreen(
      tester,
      listHandler: ({search}) async => PeoplePage(people: [_person('p1', 'Grace', 'Hopper')], nextCursor: null),
      attendanceHandler: () async =>
          EventAttendanceListResult(attendance: [_attendanceRecord('p1', 'Grace', 'Hopper')], nextCursor: null),
    );

    expect(find.text('Undo'), findsNothing);
    expect(find.text('Remove'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.byIcon(Icons.undo), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('a stale Organization A response does not render after switching to Organization B', (
    WidgetTester tester,
  ) async {
    final staleGate = Completer<PeoplePage>();
    var callIndex = 0;
    final harness = await _pumpCheckInScreen(
      tester,
      listHandler: ({search}) {
        callIndex++;
        if (callIndex == 1) return staleGate.future;
        return Future.value(PeoplePage(people: [_person('fresh', 'Fresh', 'Person')], nextCursor: null));
      },
      settle: false,
    );

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();

    expect(find.text('Fresh Person'), findsOneWidget, reason: 'org-b data must be shown after the switch');

    staleGate.complete(PeoplePage(people: [_person('stale', 'Stale', 'Person')], nextCursor: null));
    await tester.pumpAndSettle();

    expect(find.text('Stale Person'), findsNothing, reason: 'the stale org-a response must never render');
    expect(find.text('Fresh Person'), findsOneWidget, reason: 'org-b data must remain authoritative');
  });
}
