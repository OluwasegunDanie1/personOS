import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_api.dart';
import '../features/auth/auth_session_controller.dart';
import '../features/dashboard/dashboard_api.dart';
import '../features/events/events_api.dart';
import '../features/notifications/notifications_api.dart';
import '../features/organizations/organizations_api.dart';
import '../features/people/people_api.dart';
import 'api/api_client.dart';
import 'storage/app_preferences.dart';
import 'storage/secure_token_storage.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) => SecureTokenStorage());

final appPreferencesProvider = Provider<AppPreferences>((ref) => AppPreferences());

/// One shared Dio client for the whole app. onSessionInvalidated is a
/// closure, not evaluated until a refresh failure actually occurs, so this
/// does not create a circular initialization with authSessionControllerProvider.
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(secureTokenStorageProvider);

  return createApiClient(
    tokenStorage: tokenStorage,
    onSessionInvalidated: () => ref.read(authSessionControllerProvider.notifier).invalidateSession(),
  );
});

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));

final organizationsApiProvider = Provider<OrganizationsApi>((ref) => OrganizationsApi(ref.watch(dioProvider)));

final dashboardApiProvider = Provider<DashboardApi>((ref) => DashboardApi(ref.watch(dioProvider)));

final peopleApiProvider = Provider<PeopleApi>((ref) => PeopleApi(ref.watch(dioProvider)));

final eventsApiProvider = Provider<EventsApi>((ref) => EventsApi(ref.watch(dioProvider)));

final notificationsApiProvider = Provider<NotificationsApi>((ref) => NotificationsApi(ref.watch(dioProvider)));
