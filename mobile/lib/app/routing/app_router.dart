import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_session_controller.dart';
import '../../features/auth/create_account_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/dashboard/home_screen.dart';
import '../../features/events/create_event_screen.dart';
import '../../features/events/edit_event_screen.dart';
import '../../features/events/event_attendance_screen.dart';
import '../../features/events/event_check_in_screen.dart';
import '../../features/events/event_detail_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/organizations/edit_organization_screen.dart';
import '../../features/organizations/organization_context_controller.dart';
import '../../features/organizations/organization_ready_screen.dart';
import '../../features/organizations/organization_setup_screen.dart';
import '../../features/people/add_person_screen.dart';
import '../../features/people/create_follow_up_screen.dart';
import '../../features/people/edit_person_screen.dart';
import '../../features/people/people_screen.dart';
import '../../features/people/person_profile_screen.dart';
import '../../features/workspace/my_profile_screen.dart';
import '../../features/workspace/organization_members_screen.dart';
import '../../features/workspace/roles_permissions_screen.dart';
import '../../features/workspace/workspace_screen.dart';
import '../splash_screen.dart';
import 'primary_navigation_shell.dart';

const splashPath = '/splash';
const welcomePath = '/welcome';
const onboardingPath = '/onboarding';
const signInPath = '/sign-in';
const createAccountPath = '/create-account';
const forgotPasswordPath = '/forgot-password';
const resetPasswordPath = '/reset-password';
const organizationSetupPath = '/organization-setup';
const organizationReadyPath = '/organization-ready';
const shellPaths = ['/home', '/people', '/events', '/messages', '/workspace'];

/// Pre-authentication paths reachable while unauthenticated (Product Task
/// 074/077): the onboarding carousel, Welcome, Sign In, and the real Create
/// Account / Forgot Password / Reset Password flows. None of these requires
/// an existing session.
const _preAuthPaths = [
  onboardingPath,
  welcomePath,
  signInPath,
  createAccountPath,
  forgotPasswordPath,
  resetPasswordPath,
];

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
    // The onboarding carousel is the pre-auth entry point (Product Task
    // 077): there is no persisted "has seen onboarding" flag, so every
    // unauthenticated session starts there.
    return _preAuthPaths.contains(location) ? null : onboardingPath;
  }

  final isAtEntryPoint = location == splashPath || _preAuthPaths.contains(location);

  if (organizationContext is OrganizationContextRestoring) {
    return location == splashPath ? null : splashPath;
  }

  if (organizationContext is OrganizationContextEmpty || organizationContext is OrganizationContextFailure) {
    return location == organizationSetupPath ? null : organizationSetupPath;
  }

  // OrganizationContextActive: authenticated users with an active
  // organization must land on the primary navigation shell, never remain on
  // splash/sign-in/organization-setup. organizationReadyPath is the one
  // deliberate exception (Product Task 077): it is reached only right after
  // a real organization-creation success, and must not be skipped.
  if (location == organizationReadyPath) {
    return null;
  }
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
      // The pre-auth entry sequence (Product Task 077): onboarding carousel
      // first, then the real Welcome entry-actions screen.
      GoRoute(path: onboardingPath, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: welcomePath, builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: signInPath,
        builder: (context, state) => SignInScreen(successMessage: state.extra as String?),
      ),
      // Real Create Account / Forgot Password / Reset Password flows
      // (Product Task 072/074), reachable pre-authentication.
      GoRoute(path: createAccountPath, builder: (context, state) => const CreateAccountScreen()),
      GoRoute(path: forgotPasswordPath, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: resetPasswordPath,
        builder: (context, state) => ResetPasswordScreen(prefilledToken: state.extra as String?),
      ),
      GoRoute(path: organizationSetupPath, builder: (context, state) => const OrganizationSetupScreen()),
      // Reached only right after a real POST /organizations success (Product
      // Task 077) — see resolveRedirect's organizationReadyPath exemption.
      GoRoute(path: organizationReadyPath, builder: (context, state) => const OrganizationReadyScreen()),
      // Pushed above the shell (not a StatefulShellBranch), so the primary
      // bottom navigation is not visible on this screen, matching the
      // frozen Add Person reference.
      GoRoute(path: '/people/add', builder: (context, state) => const AddPersonScreen()),
      // Declared after the static '/people/add' route above (list order
      // determines match precedence for sibling routes), so an 'add' path
      // segment is never captured as a personId. Pushed above the shell —
      // personId only, no organizationId and no whole-Person object — per
      // the frozen Person Profile reference's own back-affordance/no-bottom-
      // nav composition.
      GoRoute(
        path: '/people/:personId',
        builder: (context, state) => PersonProfileScreen(personId: state.pathParameters['personId']!),
      ),
      // Also pushed above the shell — personId only, no organizationId, no
      // PersonDetail passed as route state. The Create Follow-up screen has
      // its own back affordance (Product Task 043).
      GoRoute(
        path: '/people/:personId/follow-ups/create',
        builder: (context, state) => CreateFollowUpScreen(personId: state.pathParameters['personId']!),
      ),
      // Also pushed above the shell — personId only, no organizationId, no
      // PersonDetail/PersonSummary passed as route state (Product Task
      // 047). Edit Person owns its own authoritative Person Detail load.
      GoRoute(
        path: '/people/:personId/edit',
        builder: (context, state) => EditPersonScreen(personId: state.pathParameters['personId']!),
      ),
      // Also pushed above the shell — no route parameters, since both
      // screens use only the already-selected organization context (Product
      // Task 052). No direct frozen "Organization Members" list screen
      // exists; Roles & Permissions matches design/ui-reference/12.png's own
      // back-affordance/no-bottom-nav composition.
      GoRoute(path: '/workspace/members', builder: (context, state) => const OrganizationMembersScreen()),
      GoRoute(path: '/workspace/roles', builder: (context, state) => const RolesPermissionsScreen()),
      // Also pushed above the shell (Product Task 080) — real, authority-
      // backed additions identified by Product Task 079's audit: a read-only
      // My Profile view and an Organization Name edit surface.
      GoRoute(path: '/workspace/profile', builder: (context, state) => const MyProfileScreen()),
      GoRoute(path: '/workspace/organization', builder: (context, state) => const EditOrganizationScreen()),
      // Pushed above the shell (Product Task 062), mirroring '/people/add'
      // exactly. Declared before the dynamic '/events/:eventId' route below
      // (list order determines match precedence for sibling routes), so a
      // 'create' path segment is never captured as an eventId.
      GoRoute(path: '/events/create', builder: (context, state) => const CreateEventScreen()),
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) => EventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/:eventId/edit',
        builder: (context, state) => EditEventScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/:eventId/attendance',
        builder: (context, state) => EventAttendanceScreen(eventId: state.pathParameters['eventId']!),
      ),
      // Pushed above the shell (Product Task 069) — real Check-In flow
      // using the existing POST .../attendance endpoint.
      GoRoute(
        path: '/events/:eventId/check-in',
        builder: (context, state) => EventCheckInScreen(eventId: state.pathParameters['eventId']!),
      ),
      // Pushed above the shell (Product Task 066) — no route parameters,
      // reached from Home's bell icon, mirroring '/workspace/members'
      // exactly (uses only the already-selected organization context).
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
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
