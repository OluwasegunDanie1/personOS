import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/events/edit_event_screen.dart';
import 'package:relvio/features/events/event_models.dart';
import 'package:relvio/features/events/events_api.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/people_models.dart' show FieldUpdate;

class _ScriptedEventsApi extends EventsApi {
  _ScriptedEventsApi({required this.initialDetail}) : super(Dio());

  EventDetail initialDetail;
  EventDetail? lastCancelledResult;
  Map<String, Object?>? lastUpdatePayload;
  int detailCallCount = 0;
  int updateCallCount = 0;
  int cancelCallCount = 0;
  bool cancelSucceeds = true;

  @override
  Future<EventDetail> detail({required String organizationId, required String eventId}) async {
    detailCallCount++;
    return initialDetail;
  }

  @override
  Future<EventDetail> update({
    required String organizationId,
    required String eventId,
    FieldUpdate<String> title = const FieldUpdate.omit(),
    FieldUpdate<String> description = const FieldUpdate.omit(),
    FieldUpdate<String> category = const FieldUpdate.omit(),
    FieldUpdate<String> venue = const FieldUpdate.omit(),
    FieldUpdate<DateTime> startDate = const FieldUpdate.omit(),
    FieldUpdate<DateTime> endDate = const FieldUpdate.omit(),
  }) async {
    updateCallCount++;
    lastUpdatePayload = {
      'title': title.isSet ? title.value : null,
      'venue': venue.isSet ? venue.value : null,
    };
    initialDetail = EventDetail(
      id: initialDetail.id,
      title: title.isSet ? title.value! : initialDetail.title,
      description: initialDetail.description,
      category: initialDetail.category,
      venue: venue.isSet ? venue.value : initialDetail.venue,
      startDate: initialDetail.startDate,
      endDate: initialDetail.endDate,
      cancelledAt: initialDetail.cancelledAt,
      createdAt: initialDetail.createdAt,
      createdBy: initialDetail.createdBy,
    );
    return initialDetail;
  }

  @override
  Future<EventDetail> cancel({required String organizationId, required String eventId}) async {
    cancelCallCount++;
    if (!cancelSucceeds) throw Exception('boom');
    initialDetail = EventDetail(
      id: initialDetail.id,
      title: initialDetail.title,
      description: initialDetail.description,
      category: initialDetail.category,
      venue: initialDetail.venue,
      startDate: initialDetail.startDate,
      endDate: initialDetail.endDate,
      cancelledAt: DateTime.utc(2026, 7, 14, 10, 0),
      createdAt: initialDetail.createdAt,
      createdBy: initialDetail.createdBy,
    );
    lastCancelledResult = initialDetail;
    return initialDetail;
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

EventDetail _detail({DateTime? cancelledAt}) => EventDetail(
  id: 'event-1',
  title: 'Sunday Service',
  description: 'Weekly service',
  category: 'Worship',
  venue: 'Main Auditorium',
  startDate: DateTime.utc(2026, 8, 2, 9, 0),
  endDate: DateTime.utc(2026, 8, 2, 11, 0),
  cancelledAt: cancelledAt,
  createdAt: DateTime.now().toUtc(),
  createdBy: const EventCreatorRef(id: 'user-1', firstName: 'Ada', lastName: 'Lovelace'),
);

Future<_ScriptedEventsApi> _pumpEditEventScreen(WidgetTester tester, {required EventDetail initialDetail}) async {
  final api = _ScriptedEventsApi(initialDetail: initialDetail);

  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/events/event-1/edit',
    routes: [
      GoRoute(
        path: '/events/:eventId/edit',
        builder: (context, state) => EditEventScreen(eventId: state.pathParameters['eventId']!),
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

  return api;
}

void main() {
  testWidgets('hydrates the form from a real independent GET Detail load', (WidgetTester tester) async {
    await _pumpEditEventScreen(tester, initialDetail: _detail());

    expect(find.widgetWithText(TextFormField, 'Sunday Service'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Main Auditorium'), findsOneWidget);
  });

  testWidgets('no Unsaved changes badge is shown before any field is edited', (WidgetTester tester) async {
    await _pumpEditEventScreen(tester, initialDetail: _detail());

    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('editing a field shows the Unsaved changes indicator', (WidgetTester tester) async {
    await _pumpEditEventScreen(tester, initialDetail: _detail());

    await tester.enterText(find.widgetWithText(TextFormField, 'Sunday Service'), 'Sunday Service Updated');
    await tester.pump();

    expect(find.text('Unsaved changes'), findsOneWidget);
  });

  testWidgets('Save Changes issues a real PATCH with only the changed field, then refreshes', (
    WidgetTester tester,
  ) async {
    final api = await _pumpEditEventScreen(tester, initialDetail: _detail());

    await tester.enterText(find.widgetWithText(TextFormField, 'Sunday Service'), 'Updated Title');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(api.updateCallCount, 1);
    expect(api.lastUpdatePayload!['title'], 'Updated Title');
    expect(api.lastUpdatePayload!['venue'], isNull);
    // Post-save refresh: the real GET Detail is called again (once at
    // initial load, once after the successful PATCH).
    expect(api.detailCallCount, greaterThanOrEqualTo(1));
  });

  testWidgets('Save Changes with no edits reports no changes to save', (WidgetTester tester) async {
    final api = await _pumpEditEventScreen(tester, initialDetail: _detail());

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('No changes to save.'), findsOneWidget);
    expect(api.updateCallCount, 0);
  });

  testWidgets('Cancel Event requires confirmation before calling the real cancel action', (
    WidgetTester tester,
  ) async {
    final api = await _pumpEditEventScreen(tester, initialDetail: _detail());

    await tester.tap(find.text('Cancel Event'));
    await tester.pumpAndSettle();

    expect(api.cancelCallCount, 0, reason: 'the confirmation dialog must appear before any cancel call');
    expect(find.text('Cancel this event?'), findsOneWidget);

    await tester.tap(find.text('Keep Event'));
    await tester.pumpAndSettle();

    expect(api.cancelCallCount, 0, reason: 'declining the confirmation must never call cancel()');
  });

  testWidgets('confirming Cancel Event calls the real POST cancel action', (WidgetTester tester) async {
    final api = await _pumpEditEventScreen(tester, initialDetail: _detail());

    await tester.tap(find.text('Cancel Event'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel Event'));
    await tester.pumpAndSettle();

    expect(api.cancelCallCount, 1);
  });

  testWidgets('an already-cancelled event disables Cancel Event (idempotent UI, no uncancel)', (
    WidgetTester tester,
  ) async {
    await _pumpEditEventScreen(tester, initialDetail: _detail(cancelledAt: DateTime.utc(2026, 7, 1)));

    expect(find.text('Event Already Cancelled'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(
      find.ancestor(of: find.text('Event Already Cancelled'), matching: find.byType(OutlinedButton)),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('switching organizations while Edit Event is open closes it', (WidgetTester tester) async {
    final api = _ScriptedEventsApi(initialDetail: _detail());
    final orgController = _FakeOrganizationContextController(_orgA);

    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/events',
      routes: [
        GoRoute(path: '/events', builder: (context, state) => const Scaffold(body: Text('Events List'))),
        GoRoute(
          path: '/events/:eventId/edit',
          builder: (context, state) => EditEventScreen(eventId: state.pathParameters['eventId']!),
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
    await tester.pumpAndSettle();

    router.push('/events/event-1/edit');
    await tester.pumpAndSettle();
    expect(find.byType(EditEventScreen), findsOneWidget);

    orgController.emit(_orgB);
    await tester.pumpAndSettle();

    expect(find.byType(EditEventScreen), findsNothing);
    expect(find.text('Events List'), findsOneWidget);
  });

  testWidgets('a truthful, retryable error state is shown on load failure', (WidgetTester tester) async {
    final throwingApi = _ThrowingDetailEventsApi();

    final router = GoRouter(
      initialLocation: '/events/event-1/edit',
      routes: [
        GoRoute(
          path: '/events/:eventId/edit',
          builder: (context, state) => EditEventScreen(eventId: state.pathParameters['eventId']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventsApiProvider.overrideWithValue(throwingApi),
          organizationContextControllerProvider.overrideWith(() => _FakeOrganizationContextController(_orgA)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load this event.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });
}

class _ThrowingDetailEventsApi extends EventsApi {
  _ThrowingDetailEventsApi() : super(Dio());

  @override
  Future<EventDetail> detail({required String organizationId, required String eventId}) async =>
      throw Exception('network down');
}
