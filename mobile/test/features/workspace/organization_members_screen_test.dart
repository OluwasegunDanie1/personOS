import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/app/routing/primary_navigation_shell.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/auth/auth_models.dart';
import 'package:relvio/features/auth/auth_session_controller.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/organizations/organizations_api.dart';
import 'package:relvio/features/workspace/organization_members_screen.dart';
import 'package:relvio/features/workspace/workspace_screen.dart';

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

typedef _MembersHandler = Future<List<OrganizationMemberSummary>> Function(String organizationId);

class _ScriptedOrganizationsApi extends OrganizationsApi {
  _ScriptedOrganizationsApi({required this.membersHandler}) : super(Dio());

  _MembersHandler membersHandler;
  int listMembersCallCount = 0;

  @override
  Future<List<OrganizationSummary>> list() async => const [];

  @override
  Future<List<OrganizationMemberSummary>> listMembers(String organizationId) {
    listMembersCallCount++;
    return membersHandler(organizationId);
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

OrganizationMemberSummary _member(String membershipId, {String firstName = 'Ada', String roleName = 'Owner'}) =>
    OrganizationMemberSummary(
      membershipId: membershipId,
      user: OrganizationMemberUser(
        id: 'user-$membershipId',
        firstName: firstName,
        lastName: 'Lovelace',
        email: '$firstName@example.com',
      ),
      role: OrganizationRole(id: 'role-1', name: roleName),
    );

class _Harness {
  _Harness(this.router, this.orgController, this.api);
  final GoRouter router;
  final _FakeOrganizationContextController orgController;
  final _ScriptedOrganizationsApi api;
}

Future<_Harness> _pumpMembersScreen(
  WidgetTester tester, {
  required _MembersHandler membersHandler,
  OrganizationContextState initialOrg = _orgA,
  bool startFromWorkspace = false,
  bool settle = true,
}) async {
  final api = _ScriptedOrganizationsApi(membersHandler: membersHandler);
  final orgController = _FakeOrganizationContextController(initialOrg);

  final router = GoRouter(
    initialLocation: '/workspace',
    routes: [
      GoRoute(path: '/workspace/members', builder: (context, state) => const OrganizationMembersScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => PrimaryNavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/workspace', builder: (context, state) => const WorkspaceScreen())],
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        organizationsApiProvider.overrideWithValue(api),
        organizationContextControllerProvider.overrideWith(() => orgController),
        authSessionControllerProvider.overrideWith(_FakeAuthSessionController.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  if (startFromWorkspace) {
    await tester.tap(find.text('Organization Members'));
    await tester.pumpAndSettle();
  } else {
    router.push('/workspace/members');
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // A gated/never-completing handler leaves a CircularProgressIndicator's
      // indeterminate animation running forever, which pumpAndSettle cannot
      // settle — pump explicitly instead.
      await tester.pump();
    }
  }

  return _Harness(router, orgController, api);
}

void main() {
  testWidgets('the Workspace "Organization Members" tile enters /workspace/members', (WidgetTester tester) async {
    final harness = await _pumpMembersScreen(
      tester,
      membersHandler: (organizationId) async => [],
      startFromWorkspace: true,
    );

    expect(harness.router.state.uri.toString(), '/workspace/members');
    expect(find.text('Organization Members'), findsWidgets);
  });

  testWidgets('Organization Members route is outside the bottom-navigation shell', (WidgetTester tester) async {
    await _pumpMembersScreen(tester, membersHandler: (organizationId) async => []);

    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('renders real member data: name, email, role badge', (WidgetTester tester) async {
    await _pumpMembersScreen(
      tester,
      membersHandler: (organizationId) async => [_member('m1', firstName: 'Grace', roleName: 'Administrator')],
    );

    expect(find.text('Grace Lovelace'), findsOneWidget);
    expect(find.text('Grace@example.com'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
  });

  testWidgets('a truthful empty state is shown when there are no members', (WidgetTester tester) async {
    await _pumpMembersScreen(tester, membersHandler: (organizationId) async => []);

    expect(find.text('No members yet.'), findsOneWidget);
  });

  testWidgets('a truthful, retryable error state is shown on load failure', (WidgetTester tester) async {
    await _pumpMembersScreen(tester, membersHandler: (organizationId) async => throw Exception('network down'));

    expect(find.text('Could not load organization members.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('retry reloads real data after a failure', (WidgetTester tester) async {
    var shouldFail = true;
    final harness = await _pumpMembersScreen(
      tester,
      membersHandler: (organizationId) async {
        if (shouldFail) throw Exception('boom');
        return [_member('m1')];
      },
    );

    expect(find.text('Could not load organization members.'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(harness.api.listMembersCallCount, greaterThanOrEqualTo(2));
  });

  testWidgets('no invite, remove, or role-change control exists anywhere on this screen', (
    WidgetTester tester,
  ) async {
    await _pumpMembersScreen(tester, membersHandler: (organizationId) async => [_member('m1')]);

    expect(find.text('Invite'), findsNothing);
    expect(find.text('Remove'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.person_add_alt_1), findsNothing);
    expect(find.byType(PopupMenuButton<Object?>), findsNothing);
  });

  testWidgets('a stale Organization A response does not render after switching to Organization B', (
    WidgetTester tester,
  ) async {
    final staleGate = Completer<List<OrganizationMemberSummary>>();
    var callIndex = 0;
    final harness = await _pumpMembersScreen(
      tester,
      membersHandler: (organizationId) {
        callIndex++;
        if (callIndex == 1) return staleGate.future;
        return Future.value([_member('fresh-m1', firstName: 'Fresh')]);
      },
      settle: false,
    );

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();

    expect(find.text('Fresh Lovelace'), findsOneWidget, reason: 'org-b data must be shown after the switch');

    staleGate.complete([_member('stale-m1', firstName: 'Stale')]);
    await tester.pumpAndSettle();

    expect(find.text('Stale Lovelace'), findsNothing, reason: 'the stale org-a response must never render');
    expect(find.text('Fresh Lovelace'), findsOneWidget, reason: 'org-b data must remain authoritative');
  });
}
