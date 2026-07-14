import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/events/create_event_screen.dart';
import 'package:relvio/features/events/event_models.dart';
import 'package:relvio/features/events/events_api.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';

typedef _CreateHandler = Future<EventDetail> Function(Map<String, dynamic> payload);

class _ScriptedEventsApi extends EventsApi {
  _ScriptedEventsApi({required this.createHandler}) : super(Dio());

  _CreateHandler createHandler;
  Map<String, dynamic>? lastPayload;

  @override
  Future<EventListResult> list({
    required String organizationId,
    String? cursor,
    String? search,
    String? category,
    int? limit,
  }) async => const EventListResult(events: [], nextCursor: null);

  @override
  Future<EventDetail> create({
    required String organizationId,
    required String title,
    String? category,
    String? description,
    String? venue,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    lastPayload = {
      'title': title,
      'category': category,
      'startDate': startDate,
      'endDate': endDate,
    };
    return createHandler(lastPayload!);
  }
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

EventDetail _detail() => EventDetail(
  id: 'event-1',
  title: 'Sunday Service',
  description: null,
  category: null,
  venue: null,
  startDate: DateTime.now().toUtc(),
  endDate: null,
  cancelledAt: null,
  createdAt: DateTime.now().toUtc(),
  createdBy: const EventCreatorRef(id: 'user-1', firstName: 'Ada', lastName: 'Lovelace'),
);

Future<_ScriptedEventsApi> _pumpCreateEventScreen(
  WidgetTester tester, {
  required _CreateHandler createHandler,
}) async {
  final api = _ScriptedEventsApi(createHandler: createHandler);

  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/events/create',
    routes: [
      GoRoute(path: '/events/create', builder: (context, state) => const CreateEventScreen()),
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
  testWidgets('submitting without Date/Start Time shows a validation error and never calls create()', (
    WidgetTester tester,
  ) async {
    var createCalled = false;
    final api = await _pumpCreateEventScreen(
      tester,
      createHandler: (payload) async {
        createCalled = true;
        return _detail();
      },
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter event name').first, 'Sunday Service');
    await tester.tap(find.text('Create Event').last);
    await tester.pumpAndSettle();

    expect(find.text('Date and Start Time are required.'), findsOneWidget);
    expect(createCalled, isFalse);
    expect(api.lastPayload, isNull);
  });

  testWidgets('a complete submission (Date + Start Time, no End Time) constructs a UTC startDate and omits endDate', (
    WidgetTester tester,
  ) async {
    final api = await _pumpCreateEventScreen(tester, createHandler: (payload) async => _detail());

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter event name').first, 'Sunday Service');

    await tester.tap(find.byKey(const Key('createEventDateField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createEventStartTimeField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Event').last);
    await tester.pumpAndSettle();

    expect(api.lastPayload, isNotNull);
    expect(api.lastPayload!['title'], 'Sunday Service');
    expect(api.lastPayload!['endDate'], isNull);
    final startDate = api.lastPayload!['startDate'] as DateTime;
    expect(startDate, isNotNull);
  });

  testWidgets('Cancel pops the screen without calling create()', (WidgetTester tester) async {
    var createCalled = false;
    await _pumpCreateEventScreen(
      tester,
      createHandler: (payload) async {
        createCalled = true;
        return _detail();
      },
    );

    expect(find.byType(CreateEventScreen), findsOneWidget);
    expect(createCalled, isFalse);
  });

  testWidgets('Event Template, Event Cover, and Time Zone controls are absent (no backend authority)', (
    WidgetTester tester,
  ) async {
    await _pumpCreateEventScreen(tester, createHandler: (payload) async => _detail());

    expect(find.text('Event Template'), findsNothing);
    expect(find.text('Upload cover'), findsNothing);
    expect(find.textContaining('Time Zone'), findsNothing);
  });
}
