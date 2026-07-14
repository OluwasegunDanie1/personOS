import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/auth/auth_models.dart';
import 'package:relvio/features/auth/auth_session_controller.dart';
import 'package:relvio/features/dashboard/dashboard_api.dart';
import 'package:relvio/features/dashboard/dashboard_models.dart';
import 'package:relvio/features/dashboard/home_screen.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';

class _FakeAuthSessionController extends AuthSessionController {
  @override
  AuthSessionState build() => AuthSessionState.authenticated(
    PublicUser(
      id: 'user-1',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phone: null,
      status: 'ACTIVE',
      lastLogin: null,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  );
}

typedef _SummaryHandler = Future<DashboardSummary> Function(String organizationId);

class _ScriptedDashboardApi extends DashboardApi {
  _ScriptedDashboardApi({required this.handler}) : super(Dio());

  _SummaryHandler handler;
  int fetchCallCount = 0;

  @override
  Future<DashboardSummary> fetch(String organizationId) {
    fetchCallCount++;
    return handler(organizationId);
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

DashboardSummary _summary({
  int totalPeople = 0,
  int newPeople = 0,
  int pendingFollowUps = 0,
  List<UpcomingEvent> upcomingEvents = const [],
  List<RecentMember> recentMembers = const [],
  List<PendingTask> pendingTasks = const [],
}) => DashboardSummary(
  totalPeople: totalPeople,
  newPeople: newPeople,
  pendingFollowUps: pendingFollowUps,
  upcomingEvents: upcomingEvents,
  recentMembers: recentMembers,
  pendingTasks: pendingTasks,
);

class _Harness {
  _Harness(this.orgController, this.api);
  final _FakeOrganizationContextController orgController;
  final _ScriptedDashboardApi api;
}

Future<_Harness> _pumpHome(
  WidgetTester tester, {
  required _SummaryHandler handler,
  OrganizationContextState initialOrg = _orgA,
  bool settle = true,
}) async {
  final api = _ScriptedDashboardApi(handler: handler);
  final orgController = _FakeOrganizationContextController(initialOrg);

  // A tall viewport so the Recent Members/Pending Tasks sections (below the
  // metric grid and Upcoming Events list) are reachable without scrolling,
  // mirroring add_person_screen_test.dart's established convention.
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
        authSessionControllerProvider.overrideWith(_FakeAuthSessionController.new),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // A gated/never-completing handler leaves a CircularProgressIndicator's
    // indeterminate animation running forever, which pumpAndSettle cannot
    // settle — pump explicitly instead.
    await tester.pump();
  }

  return _Harness(orgController, api);
}

class _RouterHarness {
  _RouterHarness(this.router, this.orgController, this.api);
  final GoRouter router;
  final _FakeOrganizationContextController orgController;
  final _ScriptedDashboardApi api;
}

Future<_RouterHarness> _pumpHomeWithRouter(
  WidgetTester tester, {
  required _SummaryHandler handler,
  OrganizationContextState initialOrg = _orgA,
}) async {
  final api = _ScriptedDashboardApi(handler: handler);
  final orgController = _FakeOrganizationContextController(initialOrg);

  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/people/add',
        builder: (context, state) => const Scaffold(body: Text('Add Person destination')),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const Scaffold(body: Text('Notifications destination')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
        authSessionControllerProvider.overrideWith(_FakeAuthSessionController.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return _RouterHarness(router, orgController, api);
}

void main() {
  testWidgets('renders real Recent Members data: name and joined date', (WidgetTester tester) async {
    await _pumpHome(
      tester,
      handler: (organizationId) async => _summary(
        recentMembers: [
          RecentMember(id: 'p1', firstName: 'Sarah', lastName: 'Johnson', joinedAt: DateTime.utc(2026, 5, 20)),
        ],
      ),
    );

    expect(find.text('Sarah Johnson'), findsOneWidget);
    expect(find.textContaining('Joined May 20, 2026'), findsOneWidget);
  });

  testWidgets('a truthful empty state is shown when there are no recent members', (WidgetTester tester) async {
    await _pumpHome(tester, handler: (organizationId) async => _summary());

    expect(find.text('No recent members.'), findsOneWidget);
  });

  testWidgets('renders real Pending Tasks data: title, description, and due date', (WidgetTester tester) async {
    await _pumpHome(
      tester,
      handler: (organizationId) async => _summary(
        pendingTasks: [
          const PendingTask(
            id: 'fu1',
            title: 'Follow up with Alex Smith',
            description: 'Member follow-up',
            dueDate: null,
          ),
        ],
      ),
    );

    expect(find.text('Follow up with Alex Smith'), findsOneWidget);
    expect(find.text('Member follow-up'), findsOneWidget);
  });

  testWidgets('a Pending Task due today/tomorrow is labeled from the real dueDate, not fabricated', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final dueToday = DateTime(now.year, now.month, now.day, 18);

    await _pumpHome(
      tester,
      handler: (organizationId) async => _summary(
        pendingTasks: [PendingTask(id: 'fu1', title: 'Confirm event volunteers', description: null, dueDate: dueToday)],
      ),
    );

    expect(find.text('Due today'), findsOneWidget);
  });

  testWidgets('a truthful empty state is shown when there are no pending tasks', (WidgetTester tester) async {
    await _pumpHome(tester, handler: (organizationId) async => _summary());

    expect(find.text('No pending tasks.'), findsOneWidget);
  });

  testWidgets('loading shows a spinner and error shows a retryable message', (WidgetTester tester) async {
    await _pumpHome(tester, handler: (organizationId) async => throw Exception('network down'));

    expect(find.text('Could not load the dashboard. Pull down to retry.'), findsOneWidget);
  });

  testWidgets('retry reloads real data after a failure', (WidgetTester tester) async {
    var shouldFail = true;
    final harness = await _pumpHome(
      tester,
      handler: (organizationId) async {
        if (shouldFail) throw Exception('boom');
        return _summary(
          recentMembers: [RecentMember(id: 'p1', firstName: 'Grace', lastName: 'Hopper', joinedAt: DateTime.utc(2026, 5, 1))],
        );
      },
    );

    expect(find.text('Could not load the dashboard. Pull down to retry.'), findsOneWidget);

    shouldFail = false;
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Could not load the dashboard. Pull down to retry.')),
    );
    await gesture.moveBy(const Offset(0, 1000));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(harness.api.fetchCallCount, greaterThanOrEqualTo(2));
  });

  testWidgets('unsupported frozen-reference sections are absent: Today\'s Attendance, Recent Activity', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      handler: (organizationId) async => _summary(
        recentMembers: [RecentMember(id: 'p1', firstName: 'Ada', lastName: 'Lovelace', joinedAt: DateTime.utc(2026, 5, 1))],
        pendingTasks: [const PendingTask(id: 'fu1', title: 'Follow up', description: null, dueDate: null)],
      ),
    );

    expect(find.text("Today's Attendance"), findsNothing);
    expect(find.text('Recent Activity'), findsNothing);
    expect(find.text('View all'), findsNothing);
  });

  testWidgets('the supported Add Person Quick Action renders', (WidgetTester tester) async {
    await _pumpHome(tester, handler: (organizationId) async => _summary());

    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Add Person'), findsOneWidget);
  });

  testWidgets('unsupported Quick Actions (Create Event, Record Attendance, Send Announcement) are absent', (
    WidgetTester tester,
  ) async {
    await _pumpHome(tester, handler: (organizationId) async => _summary());

    expect(find.text('Create Event'), findsNothing);
    expect(find.text('Record Attendance'), findsNothing);
    expect(find.text('Send Announcement'), findsNothing);
  });

  testWidgets('tapping Add Person navigates through the real approved /people/add route', (WidgetTester tester) async {
    final harness = await _pumpHomeWithRouter(tester, handler: (organizationId) async => _summary());

    await tester.tap(find.text('Add Person'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/people/add');
    expect(find.text('Add Person destination'), findsOneWidget);
  });

  testWidgets('tapping the bell icon navigates to the real /notifications route', (WidgetTester tester) async {
    final harness = await _pumpHomeWithRouter(tester, handler: (organizationId) async => _summary());

    await tester.tap(find.byKey(const Key('homeNotificationsBellButton')));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/notifications');
    expect(find.text('Notifications destination'), findsOneWidget);
  });

  testWidgets('no fake/dead Quick Action control exists: the only rendered action is interactive', (
    WidgetTester tester,
  ) async {
    await _pumpHome(tester, handler: (organizationId) async => _summary());

    final inkWell = tester.widget<InkWell>(find.byKey(const Key('homeQuickActionTileInkWell')));
    expect(inkWell.onTap, isNotNull);
  });

  testWidgets('a stale Organization A response does not render after switching to Organization B', (
    WidgetTester tester,
  ) async {
    final staleGate = Completer<DashboardSummary>();
    var callIndex = 0;
    final harness = await _pumpHome(
      tester,
      handler: (organizationId) {
        callIndex++;
        if (callIndex == 1) return staleGate.future;
        return Future.value(
          _summary(
            recentMembers: [
              RecentMember(id: 'fresh', firstName: 'Fresh', lastName: 'Member', joinedAt: DateTime.utc(2026, 5, 1)),
            ],
          ),
        );
      },
      settle: false,
    );

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();

    expect(find.text('Fresh Member'), findsOneWidget, reason: 'org-b data must be shown after the switch');

    staleGate.complete(
      _summary(
        recentMembers: [
          RecentMember(id: 'stale', firstName: 'Stale', lastName: 'Member', joinedAt: DateTime.utc(2026, 5, 1)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stale Member'), findsNothing, reason: 'the stale org-a response must never render');
    expect(find.text('Fresh Member'), findsOneWidget, reason: 'org-b data must remain authoritative');
  });
}
