import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/app/routing/primary_navigation_shell.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/people/create_follow_up_screen.dart';
import 'package:relvio/features/people/people_api.dart';
import 'package:relvio/features/people/people_models.dart';
import 'package:relvio/features/people/person_profile_screen.dart';

typedef _CreateFollowUpHandler = Future<FollowUpSummary> Function({
  required String organizationId,
  required String personId,
  required String title,
  String? description,
  DateTime? dueDate,
});

class _ScriptedPeopleApi extends PeopleApi {
  _ScriptedPeopleApi({required this.createFollowUpHandler}) : super(Dio());

  _CreateFollowUpHandler createFollowUpHandler;
  int createFollowUpCallCount = 0;
  Map<String, dynamic>? lastCreateArgs;

  @override
  Future<PeoplePage> list({
    required String organizationId,
    String? cursor,
    String? search,
    PersonStatus? status,
    int? limit,
  }) async => const PeoplePage(people: [], nextCursor: null);

  @override
  Future<PersonDetail> detail({required String organizationId, required String personId}) async => PersonDetail(
    id: personId,
    firstName: 'Ada',
    lastName: 'Lovelace',
    email: null,
    phone: null,
    status: PersonStatus.active,
    avatarUrl: null,
    joinedAt: DateTime.utc(2026, 1, 1),
    tags: const [],
    currentJourneyStage: null,
    gender: null,
    dateOfBirth: null,
    address: null,
  );

  @override
  Future<PersonJourneyView> journey({required String organizationId, required String personId}) async =>
      const PersonJourneyView(currentStage: null, history: []);

  @override
  Future<List<JourneyStageListEntry>> journeyStages({required String organizationId}) async => const [];

  @override
  Future<AttendanceSummary> attendanceSummary({required String organizationId, required String personId}) async =>
      const AttendanceSummary(totalCount: 0, currentMonthCount: 0);

  int followUpsCallCount = 0;

  @override
  Future<FollowUpListResult> personFollowUps({required String organizationId, required String personId}) async {
    followUpsCallCount++;
    return const FollowUpListResult(followUps: [], nextCursor: null);
  }

  @override
  Future<FollowUpSummary> createFollowUp({
    required String organizationId,
    required String personId,
    required String title,
    String? description,
    DateTime? dueDate,
  }) {
    createFollowUpCallCount++;
    lastCreateArgs = {
      'organizationId': organizationId,
      'personId': personId,
      'title': title,
      'description': description,
      'dueDate': dueDate,
    };
    return createFollowUpHandler(
      organizationId: organizationId,
      personId: personId,
      title: title,
      description: description,
      dueDate: dueDate,
    );
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

FollowUpSummary _createdFollowUp() => const FollowUpSummary(
  id: 'fu-new',
  title: 'New follow-up',
  description: null,
  dueDate: null,
  status: FollowUpStatus.pending,
  completedAt: null,
  person: FollowUpPersonRef(id: 'p1', firstName: 'Ada', lastName: 'Lovelace'),
  assignedTo: null,
);

class _Harness {
  _Harness(this.router, this.orgController, this.api);
  final GoRouter router;
  final _FakeOrganizationContextController orgController;
  final _ScriptedPeopleApi api;
}

Future<_Harness> _pumpCreateFollowUpScreen(
  WidgetTester tester, {
  required _CreateFollowUpHandler createFollowUpHandler,
  OrganizationContextState initialOrg = _orgA,
  bool startFromProfile = false,
}) async {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final api = _ScriptedPeopleApi(createFollowUpHandler: createFollowUpHandler);
  final orgController = _FakeOrganizationContextController(initialOrg);

  final router = GoRouter(
    initialLocation: '/people',
    routes: [
      GoRoute(
        path: '/people/:personId',
        builder: (context, state) => PersonProfileScreen(personId: state.pathParameters['personId']!),
      ),
      GoRoute(
        path: '/people/:personId/follow-ups/create',
        builder: (context, state) => CreateFollowUpScreen(personId: state.pathParameters['personId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => PrimaryNavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/people', builder: (context, state) => const Scaffold(body: Text('People Screen')))],
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        peopleApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  if (startFromProfile) {
    router.push('/people/p1');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create Follow-up'));
    await tester.pumpAndSettle();
  } else {
    router.push('/people/p1/follow-ups/create');
    await tester.pumpAndSettle();
  }

  return _Harness(router, orgController, api);
}

void main() {
  testWidgets('the Profile Create Follow-up button enters /people/:personId/follow-ups/create', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpCreateFollowUpScreen(
      tester,
      createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async =>
          _createdFollowUp(),
      startFromProfile: true,
    );

    expect(harness.router.state.uri.toString(), '/people/p1/follow-ups/create');
    expect(find.text('Create Follow-up.'), findsOneWidget);
  });

  testWidgets('Create Follow-up route is outside the bottom-navigation shell', (WidgetTester tester) async {
    await _pumpCreateFollowUpScreen(
      tester,
      createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async =>
          _createdFollowUp(),
    );

    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('back returns to Person Profile', (WidgetTester tester) async {
    final harness = await _pumpCreateFollowUpScreen(
      tester,
      createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async =>
          _createdFollowUp(),
      startFromProfile: true,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/people/p1');
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('organization switch while Create Follow-up is open closes the flow to /people', (
    WidgetTester tester,
  ) async {
    final harness = await _pumpCreateFollowUpScreen(
      tester,
      createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async =>
          _createdFollowUp(),
    );

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();

    expect(find.text('People Screen'), findsOneWidget);
  });

  testWidgets('Title is required; empty submission is prevented', (WidgetTester tester) async {
    final harness = await _pumpCreateFollowUpScreen(
      tester,
      createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async =>
          _createdFollowUp(),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save Follow-up'));
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
    expect(harness.api.createFollowUpCallCount, 0);
  });

  testWidgets('Description and Due Date & Time are optional; Person/Status pickers do not exist', (
    WidgetTester tester,
  ) async {
    await _pumpCreateFollowUpScreen(
      tester,
      createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async =>
          _createdFollowUp(),
    );

    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Due Date & Time'), findsOneWidget);
    expect(find.text('Select date & time (optional)'), findsOneWidget);
    expect(find.text('Person'), findsNothing);
    expect(find.text('Status'), findsNothing);
    expect(find.text('Assignee'), findsNothing);
    for (final invented in ['Priority', 'Reminder', 'Notification', 'Escalation', 'Tags', 'Team']) {
      expect(find.text(invented), findsNothing);
    }
  });

  group('Due Date & Time (Product Task 043A)', () {
    testWidgets('submitting without selecting a due value omits dueDate entirely', (WidgetTester tester) async {
      DateTime? capturedDueDate = DateTime.now();
      var received = false;
      await _pumpCreateFollowUpScreen(
        tester,
        createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async {
          received = true;
          capturedDueDate = dueDate;
          return _createdFollowUp();
        },
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter a title'), 'A real title');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(received, isTrue);
      expect(capturedDueDate, isNull, reason: 'dueDate remains optional and is omitted, never fabricated');
    });

    testWidgets(
      'selecting both a calendar date and a wall-clock time sets a fully-resolved local due DateTime, sent to Create',
      (WidgetTester tester) async {
        DateTime? capturedDueDate;
        final harness = await _pumpCreateFollowUpScreen(
          tester,
          createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async {
            capturedDueDate = dueDate;
            return _createdFollowUp();
          },
        );

        await tester.enterText(find.widgetWithText(TextFormField, 'Enter a title'), 'A real title');

        await tester.tap(find.byKey(const Key('createFollowUpDueDateTimeField')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK')); // accepts the pre-filled (today) calendar date
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK')); // accepts the pre-filled (now) wall-clock time
        await tester.pumpAndSettle();

        // The field must now show a real resolved local date+time, never
        // the "(optional)" placeholder and never a partial state.
        expect(find.text('Select date & time (optional)'), findsNothing);

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        final now = DateTime.now();
        expect(capturedDueDate, isNotNull);
        expect(capturedDueDate!.year, now.year);
        expect(capturedDueDate!.month, now.month);
        expect(capturedDueDate!.day, now.day);
        expect(harness.api.createFollowUpCallCount, 1);
      },
    );

    testWidgets('cancelling the time picker after selecting a date leaves no due value selected (no invented instant)', (
      WidgetTester tester,
    ) async {
      DateTime? capturedDueDate = DateTime.now();
      await _pumpCreateFollowUpScreen(
        tester,
        createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async {
          capturedDueDate = dueDate;
          return _createdFollowUp();
        },
      );

      expect(find.text('Select date & time (optional)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('createFollowUpDueDateTimeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // accept the date step
      await tester.pumpAndSettle();
      // .last: the dialog's own Cancel button, distinct from the screen's
      // static bottom Cancel button.
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Select date & time (optional)'),
        findsOneWidget,
        reason: 'a date-only partial selection must never be held or displayed as a value',
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter a title'), 'A real title');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(capturedDueDate, isNull, reason: 'cancelling the time step must not submit an invented due instant');
    });

    testWidgets('cancelling the date picker leaves any existing due value unchanged', (WidgetTester tester) async {
      await _pumpCreateFollowUpScreen(
        tester,
        createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async =>
            _createdFollowUp(),
      );

      await tester.tap(find.byKey(const Key('createFollowUpDueDateTimeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Select date & time (optional)'), findsNothing);
      final selectedText = tester.widget<Text>(find.textContaining(',').first).data;

      // Re-open and cancel at the date step this time.
      await tester.tap(find.byKey(const Key('createFollowUpDueDateTimeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text(selectedText!), findsOneWidget, reason: 'cancelling re-selection must preserve the prior value');
    });

    testWidgets('a selected due date/time can be cleared, omitting dueDate from the request', (WidgetTester tester) async {
      DateTime? capturedDueDate = DateTime.now();
      var callCount = 0;
      final harness = await _pumpCreateFollowUpScreen(
        tester,
        createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async {
          callCount++;
          capturedDueDate = dueDate;
          return _createdFollowUp();
        },
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter a title'), 'A real title');

      await tester.tap(find.byKey(const Key('createFollowUpDueDateTimeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Select date & time (optional)'), findsNothing);

      expect(find.byKey(const Key('createFollowUpClearDueDateTimeField')), findsOneWidget);
      await tester.tap(find.byKey(const Key('createFollowUpClearDueDateTimeField')));
      await tester.pumpAndSettle();

      expect(find.text('Select date & time (optional)'), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(harness.api.createFollowUpCallCount, 1);
      expect(callCount, 1);
      expect(capturedDueDate, isNull, reason: 'clearing must result in dueDate being omitted, never a stale value');
    });
  });

  testWidgets('submitting disables duplicate submit', (WidgetTester tester) async {
    final gate = Completer<FollowUpSummary>();
    final harness = await _pumpCreateFollowUpScreen(
      tester,
      createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) =>
          gate.future,
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter a title'), 'A real title');
    // PrimaryButton replaces its text label with a spinner while loading, so
    // both taps target the button by type (there is exactly one
    // FilledButton on this screen — Cancel is an OutlinedButton).
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();

    gate.complete(_createdFollowUp());
    await tester.pumpAndSettle();

    expect(harness.api.createFollowUpCallCount, 1, reason: 'a second tap while submitting must be ignored');
  });

  testWidgets('API failure keeps the form usable and preserves entered data', (WidgetTester tester) async {
    await _pumpCreateFollowUpScreen(
      tester,
      createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async =>
          throw Exception('boom'),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter a title'), 'A real title');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('boom'), findsOneWidget, reason: 'the real thrown error is surfaced as truthful feedback');
    expect(find.text('A real title'), findsOneWidget, reason: 'entered form data must be preserved after a failure');
  });

  testWidgets('success returns to Person Profile and refreshes the Follow-up region', (WidgetTester tester) async {
    final api = _ScriptedPeopleApi(
      createFollowUpHandler: ({required organizationId, required personId, required title, description, dueDate}) async =>
          _createdFollowUp(),
    );
    final orgController = _FakeOrganizationContextController(_orgA);

    final router = GoRouter(
      initialLocation: '/people',
      routes: [
        GoRoute(
          path: '/people/:personId',
          builder: (context, state) => PersonProfileScreen(personId: state.pathParameters['personId']!),
        ),
        GoRoute(
          path: '/people/:personId/follow-ups/create',
          builder: (context, state) => CreateFollowUpScreen(personId: state.pathParameters['personId']!),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => PrimaryNavigationShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/people', builder: (context, state) => const Scaffold(body: Text('People Screen'))),
              ],
            ),
          ],
        ),
      ],
    );

    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          peopleApiProvider.overrideWithValue(api),
          organizationContextControllerProvider.overrideWith(() => orgController),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.push('/people/p1');
    await tester.pumpAndSettle();
    expect(api.followUpsCallCount, 1, reason: 'the initial Profile Follow-up load');

    await tester.tap(find.widgetWithText(FilledButton, 'Create Follow-up'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter a title'), 'New follow-up');
    await tester.tap(find.widgetWithText(FilledButton, 'Save Follow-up'));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/people/p1', reason: 'success must return to Person Profile');
    expect(api.createFollowUpCallCount, 1);
    expect(api.followUpsCallCount, 2, reason: 'a real second GET request is the refresh, not a locally fabricated entry');
  });
}
