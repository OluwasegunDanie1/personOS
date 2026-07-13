import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_session_controller.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/dashboard/home_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/organizations/organization_context_controller.dart';
import '../../features/organizations/organization_setup_screen.dart';
import '../../features/people/add_person_screen.dart';
import '../../features/people/people_screen.dart';
import '../../features/workspace/workspace_screen.dart';
import '../splash_screen.dart';
import 'primary_navigation_shell.dart';

const splashPath = '/splash';
const signInPath = '/sign-in';
const organizationSetupPath = '/organization-setup';
const shellPaths = ['/home', '/people', '/events', '/messages', '/workspace'];

/// Notifies GoRouter to re-evaluate [resolveRedirect] whenever auth or
/// organization-context state changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authSessionControllerProvider, (_, _) => notifyListeners());
    ref.listen(organizationContextControllerProvider, (_, _) => notifyListeners());
  }
}

/// Pure redirect decision, factored out of [goRouterProvider] so it can be
/// exercised directly in tests without constructing a real [GoRouterState]
/// or [ProviderContainer].
String? resolveRedirect({
  required AuthSessionState authState,
  required OrganizationContextState organizationContext,
  required String location,
}) {
  if (authState.status == AuthStatus.restoring) {
    return location == splashPath ? null : splashPath;
  }

  if (authState.status == AuthStatus.unauthenticated) {
    return location == signInPath ? null : signInPath;
  }

  final isAtEntryPoint = location == splashPath || location == signInPath;

  if (organizationContext is OrganizationContextRestoring) {
    return location == splashPath ? null : splashPath;
  }

  if (organizationContext is OrganizationContextEmpty || organizationContext is OrganizationContextFailure) {
    return location == organizationSetupPath ? null : organizationSetupPath;
  }

  // OrganizationContextActive: authenticated users with an active
  // organization must land on the primary navigation shell, never remain on
  // splash/sign-in/organization-setup.
  if (isAtEntryPoint || location == organizationSetupPath) {
    return shellPaths.first;
  }

  return null;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: splashPath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => resolveRedirect(
      authState: ref.read(authSessionControllerProvider),
      organizationContext: ref.read(organizationContextControllerProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: splashPath, builder: (context, state) => const SplashScreen()),
      GoRoute(path: signInPath, builder: (context, state) => const SignInScreen()),
      GoRoute(path: organizationSetupPath, builder: (context, state) => const OrganizationSetupScreen()),
      // Pushed above the shell (not a StatefulShellBranch), so the primary
      // bottom navigation is not visible on this screen, matching the
      // frozen Add Person reference.
      GoRoute(path: '/people/add', builder: (context, state) => const AddPersonScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => PrimaryNavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/people', builder: (context, state) => const PeopleScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/events', builder: (context, state) => const EventsScreen())]),
          StatefulShellBranch(
            routes: [GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/workspace', builder: (context, state) => const WorkspaceScreen())],
          ),
        ],
      ),
    ],
  );
});
