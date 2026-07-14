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
import 'package:relvio/features/workspace/roles_permissions_screen.dart';
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

typedef _RolesHandler = Future<List<RoleSummary>> Function(String organizationId);

class _ScriptedOrganizationsApi extends OrganizationsApi {
  _ScriptedOrganizationsApi({required this.rolesHandler}) : super(Dio());

  _RolesHandler rolesHandler;
  int listRolesCallCount = 0;

  @override
  Future<List<OrganizationSummary>> list() async => const [];

  @override
  Future<List<RoleSummary>> listRoles(String organizationId) {
    listRolesCallCount++;
    return rolesHandler(organizationId);
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

RoleSummary _role(
  String id, {
  String name = 'Owner',
  String? description = 'Full access',
  List<PermissionSummary> permissions = const [],
}) => RoleSummary(id: id, name: name, description: description, permissions: permissions);

class _Harness {
  _Harness(this.router, this.orgController, this.api);
  final GoRouter router;
  final _FakeOrganizationContextController orgController;
  final _ScriptedOrganizationsApi api;
}

Future<_Harness> _pumpRolesScreen(
  WidgetTester tester, {
  required _RolesHandler rolesHandler,
  OrganizationContextState initialOrg = _orgA,
  bool startFromWorkspace = false,
  bool settle = true,
}) async {
  // A tall viewport so the Workspace tile (below the profile card and
  // organization switcher) is reachable without scrolling, mirroring
  // add_person_screen_test.dart's established convention.
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final api = _ScriptedOrganizationsApi(rolesHandler: rolesHandler);
  final orgController = _FakeOrganizationContextController(initialOrg);

  final router = GoRouter(
    initialLocation: '/workspace',
    routes: [
      GoRoute(path: '/workspace/roles', builder: (context, state) => const RolesPermissionsScreen()),
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
    await tester.tap(find.text('Roles & Permissions'));
    await tester.pumpAndSettle();
  } else {
    router.push('/workspace/roles');
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  return _Harness(router, orgController, api);
}

void main() {
  testWidgets('the Workspace "Roles & Permissions" tile enters /workspace/roles', (WidgetTester tester) async {
    final harness = await _pumpRolesScreen(
      tester,
      rolesHandler: (organizationId) async => [],
      startFromWorkspace: true,
    );

    expect(harness.router.state.uri.toString(), '/workspace/roles');
    expect(find.text('Roles & Permissions'), findsWidgets);
  });

  testWidgets('Roles & Permissions route is outside the bottom-navigation shell', (WidgetTester tester) async {
    await _pumpRolesScreen(tester, rolesHandler: (organizationId) async => []);

    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('renders real roles and the first role is selected by default with its real permissions', (
    WidgetTester tester,
  ) async {
    await _pumpRolesScreen(
      tester,
      rolesHandler: (organizationId) async => [
        _role('role-1', name: 'Owner', permissions: const [PermissionSummary(id: 'p1', name: 'people.view')]),
        _role('role-2', name: 'Member', description: null),
      ],
    );

    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Permissions for Owner'), findsOneWidget);
    expect(find.text('people.view'), findsOneWidget);
  });

  testWidgets('selecting a different role shows that role\'s real permissions', (WidgetTester tester) async {
    await _pumpRolesScreen(
      tester,
      rolesHandler: (organizationId) async => [
        _role('role-1', name: 'Owner', permissions: const [PermissionSummary(id: 'p1', name: 'people.view')]),
        _role('role-2', name: 'Member', description: null, permissions: const [
          PermissionSummary(id: 'p2', name: 'events.view'),
        ]),
      ],
    );

    await tester.tap(find.text('Member'));
    await tester.pumpAndSettle();

    expect(find.text('Permissions for Member'), findsOneWidget);
    expect(find.text('events.view'), findsOneWidget);
    expect(find.text('people.view'), findsNothing);
  });

  testWidgets('a truthful empty permissions state is shown when a role has no assigned permissions', (
    WidgetTester tester,
  ) async {
    await _pumpRolesScreen(
      tester,
      rolesHandler: (organizationId) async => [_role('role-1', name: 'Member', permissions: const [])],
    );

    expect(find.text('No permissions are assigned to this role yet.'), findsOneWidget);
  });

  testWidgets('a truthful empty state is shown when there are no roles', (WidgetTester tester) async {
    await _pumpRolesScreen(tester, rolesHandler: (organizationId) async => []);

    expect(find.text('No roles yet.'), findsOneWidget);
  });

  testWidgets('a truthful, retryable error state is shown on load failure', (WidgetTester tester) async {
    await _pumpRolesScreen(tester, rolesHandler: (organizationId) async => throw Exception('network down'));

    expect(find.text('Could not load roles.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('retry reloads real data after a failure', (WidgetTester tester) async {
    var shouldFail = true;
    await _pumpRolesScreen(
      tester,
      rolesHandler: (organizationId) async {
        if (shouldFail) throw Exception('boom');
        return [_role('role-1', name: 'Owner')];
      },
    );

    expect(find.text('Could not load roles.'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Owner'), findsOneWidget);
  });

  testWidgets('no create/edit/delete-role or assign/remove-permission control exists anywhere on this screen', (
    WidgetTester tester,
  ) async {
    await _pumpRolesScreen(
      tester,
      rolesHandler: (organizationId) async => [
        _role('role-1', name: 'Owner', permissions: const [PermissionSummary(id: 'p1', name: 'people.view')]),
      ],
    );

    expect(find.text('Save Permissions'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('a stale Organization A response does not render after switching to Organization B', (
    WidgetTester tester,
  ) async {
    final staleGate = Completer<List<RoleSummary>>();
    var callIndex = 0;
    final harness = await _pumpRolesScreen(
      tester,
      rolesHandler: (organizationId) {
        callIndex++;
        if (callIndex == 1) return staleGate.future;
        return Future.value([_role('role-fresh', name: 'Fresh Role')]);
      },
      settle: false,
    );

    harness.orgController.emit(_orgB);
    await tester.pumpAndSettle();

    expect(find.text('Fresh Role'), findsOneWidget, reason: 'org-b data must be shown after the switch');

    staleGate.complete([_role('role-stale', name: 'Stale Role')]);
    await tester.pumpAndSettle();

    expect(find.text('Stale Role'), findsNothing, reason: 'the stale org-a response must never render');
    expect(find.text('Fresh Role'), findsOneWidget, reason: 'org-b data must remain authoritative');
  });
}
