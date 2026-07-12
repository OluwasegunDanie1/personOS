import 'package:flutter_test/flutter_test.dart';
import 'package:relvio/app/routing/app_router.dart';
import 'package:relvio/features/auth/auth_models.dart';
import 'package:relvio/features/auth/auth_session_controller.dart';
import 'package:relvio/features/organizations/organization_context_controller.dart';

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

void main() {
  const restoring = AuthSessionState.restoring();
  const unauthenticated = AuthSessionState.unauthenticated();
  final authenticated = AuthSessionState.authenticated(_fixtureUser);
  const restoringOrganizationContext = OrganizationContextRestoring();
  const emptyOrganizationContext = OrganizationContextEmpty();
  const activeOrganizationContext = OrganizationContextActive(organizations: [], selectedOrganizationId: 'org-1');

  test('restoring auth always redirects to splash regardless of organization state', () {
    expect(
      resolveRedirect(authState: restoring, organizationContext: emptyOrganizationContext, location: '/home'),
      splashPath,
    );
    expect(
      resolveRedirect(authState: restoring, organizationContext: activeOrganizationContext, location: splashPath),
      isNull,
    );
  });

  test('unauthenticated always redirects to sign-in, overriding organization state', () {
    expect(
      resolveRedirect(authState: unauthenticated, organizationContext: activeOrganizationContext, location: '/home'),
      signInPath,
    );
    expect(
      resolveRedirect(authState: unauthenticated, organizationContext: emptyOrganizationContext, location: signInPath),
      isNull,
    );
  });

  test('authenticated with restoring organization context redirects to splash', () {
    expect(
      resolveRedirect(authState: authenticated, organizationContext: restoringOrganizationContext, location: '/home'),
      splashPath,
    );
  });

  test('authenticated with no organizations redirects to organization-setup', () {
    expect(
      resolveRedirect(authState: authenticated, organizationContext: emptyOrganizationContext, location: '/home'),
      organizationSetupPath,
    );
    expect(
      resolveRedirect(
        authState: authenticated,
        organizationContext: emptyOrganizationContext,
        location: organizationSetupPath,
      ),
      isNull,
    );
  });

  test('active organization context sends entry-point locations to the first shell tab', () {
    for (final entryPoint in [splashPath, signInPath, organizationSetupPath]) {
      expect(
        resolveRedirect(authState: authenticated, organizationContext: activeOrganizationContext, location: entryPoint),
        shellPaths.first,
      );
    }
  });

  test('active organization context leaves shell navigation alone', () {
    for (final path in shellPaths) {
      expect(
        resolveRedirect(authState: authenticated, organizationContext: activeOrganizationContext, location: path),
        isNull,
      );
    }
  });

  test('organization failure redirects to organization-setup same as empty', () {
    expect(
      resolveRedirect(
        authState: authenticated,
        organizationContext: const OrganizationContextFailure('network error'),
        location: '/home',
      ),
      organizationSetupPath,
    );
  });

  test('shell paths are the exact frozen five-item order', () {
    expect(shellPaths, ['/home', '/people', '/events', '/messages', '/workspace']);
  });
}
