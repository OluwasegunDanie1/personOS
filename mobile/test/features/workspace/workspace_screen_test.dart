import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relvio/app/routing/app_router.dart';
import 'package:relvio/features/auth/auth_models.dart';
import 'package:relvio/features/auth/auth_session_controller.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/workspace/workspace_screen.dart';

class _FakeAuthSessionController extends AuthSessionController {
  int logoutCallCount = 0;

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

  @override
  Future<void> logout() async {
    logoutCallCount++;
    state = const AuthSessionState.unauthenticated();
  }
}

class _FakeOrganizationContextController extends OrganizationContextController {
  _FakeOrganizationContextController(this._state);
  final OrganizationContextState _state;

  @override
  OrganizationContextState build() => _state;
}

const _activeOrg = OrganizationContextActive(
  organizations: [
    OrganizationSummary(id: 'org-1', name: 'Hope Community Church', logoUrl: null, role: OrganizationRole(id: 'r', name: 'Owner')),
  ],
  selectedOrganizationId: 'org-1',
);

class _Harness {
  _Harness(this.router, this.authController);
  final GoRouter router;
  final _FakeAuthSessionController authController;
}

Future<_Harness> _pumpWorkspaceScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final authController = _FakeAuthSessionController();

  final router = GoRouter(
    initialLocation: '/workspace',
    routes: [
      GoRoute(path: '/workspace', builder: (context, state) => const WorkspaceScreen()),
      GoRoute(path: '/workspace/profile', builder: (context, state) => const Scaffold(body: Text('My Profile Screen'))),
      GoRoute(
        path: '/workspace/organization',
        builder: (context, state) => const Scaffold(body: Text('Edit Organization Screen')),
      ),
      GoRoute(path: onboardingPath, builder: (context, state) => const Scaffold(body: Text('Onboarding Panel 1'))),
      GoRoute(path: signInPath, builder: (context, state) => const Scaffold(body: Text('Sign In Screen'))),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionControllerProvider.overrideWith(() => authController),
        organizationContextControllerProvider.overrideWith(() => _FakeOrganizationContextController(_activeOrg)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(router, authController);
}

void main() {
  testWidgets('renders the real "My Profile" and "Organization" entries', (tester) async {
    await _pumpWorkspaceScreen(tester);

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Organization'), findsOneWidget);
    expect(find.text('Edit the organization name'), findsOneWidget);
  });

  testWidgets('"My Profile" pushes /workspace/profile', (tester) async {
    final harness = await _pumpWorkspaceScreen(tester);

    await tester.tap(find.text('My Profile'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/workspace/profile');
  });

  testWidgets('"Organization" pushes /workspace/organization', (tester) async {
    final harness = await _pumpWorkspaceScreen(tester);

    await tester.tap(find.widgetWithText(ListTile, 'Organization'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), '/workspace/organization');
  });

  testWidgets('Log Out invokes the real session logout action and navigates to Sign In', (tester) async {
    final harness = await _pumpWorkspaceScreen(tester);

    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(harness.authController.logoutCallCount, 1);
    expect(harness.router.state.uri.toString(), signInPath);
    expect(find.text('Sign In Screen'), findsOneWidget);
  });

  testWidgets('Log Out never lands on onboarding panel 1', (tester) async {
    final harness = await _pumpWorkspaceScreen(tester);

    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.toString(), isNot(onboardingPath));
    expect(find.text('Onboarding Panel 1'), findsNothing);
  });
}
