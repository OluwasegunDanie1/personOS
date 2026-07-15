// ignore_for_file: depend_on_referenced_packages
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/app/routing/app_router.dart';
import 'package:relvio/core/providers.dart';
import 'package:relvio/features/auth/auth_models.dart';
import 'package:relvio/features/auth/auth_session_controller.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';
import 'package:relvio/features/organizations/organization_models.dart';
import 'package:relvio/features/organizations/organizations_api.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final _fixtureUser = PublicUser(
  id: 'user-1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: 'ada@example.com',
  phone: null,
  status: 'active',
  lastLogin: null,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

/// Authenticated immediately (skips the real token-storage restore), then
/// kicks off the real OrganizationContextController.restore() exactly as
/// AuthSessionController._restore() does in the real app, so the real
/// redirect race between the router and OrganizationSetupScreen's own
/// navigation is genuinely exercised.
class _FakeAuthSessionController extends AuthSessionController {
  @override
  AuthSessionState build() {
    Future.microtask(() => ref.read(organizationContextControllerProvider.notifier).restore());
    return AuthSessionState.authenticated(_fixtureUser);
  }
}

/// In-memory stand-in for the real network-backed OrganizationsApi: starts
/// with no organizations (Organization Setup is reached), then behaves as a
/// real backend would immediately after a real POST /organizations success.
class _FakeOrganizationsApi extends OrganizationsApi {
  _FakeOrganizationsApi() : super(Dio());

  bool _created = false;

  @override
  Future<List<OrganizationSummary>> list() async {
    if (!_created) return [];
    return const [
      OrganizationSummary(
        id: 'org-1',
        name: 'Hope Community Church',
        logoUrl: null,
        role: OrganizationRole(id: 'role-1', name: 'Owner'),
      ),
    ];
  }

  @override
  Future<OrganizationDetail> create(String name, {String? industry, String? country, String? timezone}) async {
    _created = true;
    return OrganizationDetail(id: 'org-1', name: name, industry: industry, country: country, timezone: timezone);
  }
}

void main() {
  testWidgets(
    'an org-less authenticated user reaches Organization Setup, a successful creation leaves Ready visible '
    '(never skipped to Home by the router), and only an explicit "Go to Dashboard" tap reaches the shell '
    '(Product Task 092 routing-race regression)',
    (tester) async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionControllerProvider.overrideWith(_FakeAuthSessionController.new),
            organizationsApiProvider.overrideWithValue(_FakeOrganizationsApi()),
          ],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(routerConfig: ref.watch(goRouterProvider)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Org-less authenticated user lands on Organization Setup, not Home.
      expect(find.text('Set up your organization.'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter organization name'), 'Hope Community Church');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // The real organization-context transition to Active must not let the
      // router bounce organizationSetupPath to the shell before the screen's
      // own explicit navigation runs — Ready must be the result, not Home.
      expect(find.text('Your organization is ready!'), findsOneWidget);
      expect(find.text('Set up your organization.'), findsNothing);

      // Ready remains visible on its own — no timer/auto-dismiss ever fires.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Your organization is ready!'), findsOneWidget);

      await tester.tap(find.text('Go to Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Your organization is ready!'), findsNothing);
    },
  );
}
