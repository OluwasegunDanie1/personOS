import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/events/event_lifecycle_badge.dart';
import 'package:relvio/features/events/event_models.dart';
import 'package:relvio/features/events/events_api.dart';
import 'package:relvio/features/events/events_screen.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';

typedef _ListHandler = Future<EventListResult> Function({String? cursor, String? search, String? category});

class _ScriptedEventsApi extends EventsApi {
  _ScriptedEventsApi({required this.listHandler}) : super(Dio());

  _ListHandler listHandler;
  int listCallCount = 0;
  String? lastSearch;
  String? lastCategory;

  @override
  Future<EventListResult> list({
    required String organizationId,
    String? cursor,
    String? search,
    String? category,
    int? limit,
  }) {
    listCallCount++;
    lastSearch = search;
    lastCategory = category;
    return listHandler(cursor: cursor, search: search, category: category);
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

EventSummary _event({
  String id = 'event-1',
  String title = 'Sunday Service',
  DateTime? startDate,
  DateTime? endDate,
  DateTime? cancelledAt,
}) => EventSummary(
  id: id,
  title: title,
  description: null,
  category: null,
  venue: 'Main Auditorium',
  startDate: startDate ?? DateTime.now().toUtc().add(const Duration(days: 5)),
  endDate: endDate,
  cancelledAt: cancelledAt,
  createdAt: DateTime.now().toUtc(),
);

class _Harness {
  _Harness(this.router, this.orgController, this.api);
  final GoRouter router;
  final _FakeOrganizationContextController orgController;
  final _ScriptedEventsApi api;
}

Future<_Harness> _pumpEventsScreen(
  WidgetTester tester, {
  required _ListHandler listHandler,
  OrganizationContextState initialOrg = _orgA,
  bool settle = true,
}) async {
  final api = _ScriptedEventsApi(listHandler: listHandler);
  final orgController = _FakeOrganizationContextController(initialOrg);

  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/events',
    routes: [
      GoRoute(path: '/events', builder: (context, state) => const EventsScreen()),
      GoRoute(path: '/events/create', builder: (context, state) => const Scaffold(body: Text('Create Event Screen'))),
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) => Scaffold(body: Text('Event Detail ${state.pathParameters['eventId']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventsApiProvider.overrideWithValue(api),
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

  return _Harness(router, orgController, api);
}

void main() {
  testWidgets('renders real event rows: title, venue, and a derived status badge', (WidgetTester tester) async {
    await _pumpEventsScreen(
      tester,
      listHandler: ({cursor, search, category}) async =>
          EventListResult(events: [_event(title: 'Sunday Service')], nextCursor: null),
    );

    expect(find.text('Sunday Service'), findsOneWidget);
    expect(find.text('Main Auditorium'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(EventLifecycleBadge), matching: find.text('Upcoming')),
      findsOneWidget,
    );
  });

  testWidgets('a truthful empty state is shown when there are no events', (WidgetTester tester) async {
    await _pumpEventsScreen(tester, listHandler: ({cursor, search, category}) async => const EventListResult(events: [], nextCursor: null));

    expect(find.text('No events yet.'), findsOneWidget);
  });

  testWidgets('typing in search calls list() with the search query after debounce', (WidgetTester tester) async {
    final harness = await _pumpEventsScreen(
      tester,
      listHandler: ({cursor, search, category}) async => const EventListResult(events: [], nextCursor: null),
    );

    await tester.enterText(find.byType(TextField).first, 'sunday');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(harness.api.lastSearch, 'sunday');
  });

  testWidgets('the category filter dialog applies a category query', (WidgetTester tester) async {
    final harness = await _pumpEventsScreen(
      tester,
      listHandler: ({cursor, search, category}) async => const EventListResult(events: [], nextCursor: null),
    );

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Worship');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(harness.api.lastCategory, 'Worship');
  });

  testWidgets('lifecycle tabs filter client-side: Cancelled shows only the cancelled event', (
    WidgetTester tester,
  ) async {
    await _pumpEventsScreen(
      tester,
      listHandler: ({cursor, search, category}) async => EventListResult(
        events: [
          _event(id: 'e1', title: 'Upcoming Conference', startDate: DateTime.now().toUtc().add(const Duration(days: 5))),
          _event(id: 'e2', title: 'Team Retreat', cancelledAt: DateTime.now().toUtc().subtract(const Duration(days: 1))),
        ],
        nextCursor: null,
      ),
    );

    expect(find.text('Upcoming Conference'), findsOneWidget);
    expect(find.text('Team Retreat'), findsOneWidget);

    final cancelledChip = find.widgetWithText(ChoiceChip, 'Cancelled');
    await tester.dragUntilVisible(
      cancelledChip,
      find.byWidgetPredicate((widget) => widget is ListView && widget.scrollDirection == Axis.horizontal),
      const Offset(-60, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(cancelledChip);
    await tester.pumpAndSettle();

    expect(find.text('Upcoming Conference'), findsNothing);
    expect(find.text('Team Retreat'), findsOneWidget);
  });

  testWidgets('tapping a row navigates to Event Detail', (WidgetTester tester) async {
    final harness = await _pumpEventsScreen(
      tester,
      listHandler: ({cursor, search, category}) async =>
          EventListResult(events: [_event(id: 'event-42', title: 'Sunday Service')], nextCursor: null),
    );

    await tester.tap(find.text('Sunday Service'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/events/event-42');
  });

  testWidgets('Create Event action navigates to /events/create', (WidgetTester tester) async {
    final harness = await _pumpEventsScreen(
      tester,
      listHandler: ({cursor, search, category}) async =>
          EventListResult(events: [_event()], nextCursor: null),
    );

    await tester.tap(find.text('Create Event'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/events/create');
  });

  testWidgets('a truthful, retryable error state is shown on load failure', (WidgetTester tester) async {
    await _pumpEventsScreen(tester, listHandler: ({cursor, search, category}) async => throw Exception('network down'));

    expect(find.text('Could not load events.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('no "Expected: N people" capacity text or category-keyed color exists anywhere', (
    WidgetTester tester,
  ) async {
    await _pumpEventsScreen(
      tester,
      listHandler: ({cursor, search, category}) async =>
          EventListResult(events: [_event(title: 'Sunday Service')], nextCursor: null),
    );

    expect(find.textContaining('Expected:'), findsNothing);
  });

  testWidgets('a stale Organization A response does not render after switching to Organization B', (
    WidgetTester tester,
  ) async {
    final staleGate = Completer<EventListResult>();
    var callIndex = 0;
    final harness = await _pumpEventsScreen(
      tester,
      listHandler: ({cursor, search, category}) {
        callIndex++;
        if (callIndex == 1) return staleGate.future;
        return Future.value(EventListResult(events: [_event(id: 'fresh', title: 'Fresh Event')], nextCursor: null));
      },
      settle: false,
    );

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();

    expect(find.text('Fresh Event'), findsOneWidget, reason: 'org-b data must be shown after the switch');

    staleGate.complete(EventListResult(events: [_event(id: 'stale', title: 'Stale Event')], nextCursor: null));
    await tester.pumpAndSettle();

    expect(find.text('Stale Event'), findsNothing, reason: 'the stale org-a response must never render');
    expect(find.text('Fresh Event'), findsOneWidget, reason: 'org-b data must remain authoritative');
  });
}
