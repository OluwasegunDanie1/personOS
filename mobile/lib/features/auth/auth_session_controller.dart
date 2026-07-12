import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'auth_models.dart';

enum AuthStatus { restoring, unauthenticated, authenticated }

class AuthSessionState {
  const AuthSessionState._(this.status, this.user);

  const AuthSessionState.restoring() : this._(AuthStatus.restoring, null);
  const AuthSessionState.unauthenticated() : this._(AuthStatus.unauthenticated, null);
  const AuthSessionState.authenticated(PublicUser user) : this._(AuthStatus.authenticated, user);

  final AuthStatus status;
  final PublicUser? user;
}

/// Session identity authority: the login response's PublicUser is the sole
/// source of cached identity. This controller never calls GET /auth/me or
/// GET /users/me (both remain an unresolved documentation contradiction).
class AuthSessionController extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() {
    // Restoration is async; GoRouter's redirect logic reacts to the state
    // change once it completes.
    Future.microtask(_restore);
    return const AuthSessionState.restoring();
  }

  Future<void> _restore() async {
    final tokenStorage = ref.read(secureTokenStorageProvider);
    final preferences = ref.read(appPreferencesProvider);

    final accessToken = await tokenStorage.readAccessToken();
    final refreshToken = await tokenStorage.readRefreshToken();
    final cachedUserJson = await preferences.readCachedUserJson();

    if (accessToken == null || refreshToken == null || cachedUserJson == null) {
      state = const AuthSessionState.unauthenticated();
      return;
    }

    state = AuthSessionState.authenticated(PublicUser.fromJson(cachedUserJson));
    unawaited(ref.read(organizationContextControllerProvider.notifier).restore());
  }

  Future<void> login({required String email, required String password}) async {
    final result = await ref.read(authApiProvider).login(email: email, password: password);

    await ref
        .read(secureTokenStorageProvider)
        .saveTokens(accessToken: result.accessToken, refreshToken: result.refreshToken);
    await ref.read(appPreferencesProvider).saveCachedUserJson(result.user.toJson());

    state = AuthSessionState.authenticated(result.user);
    await ref.read(organizationContextControllerProvider.notifier).restore();
  }

  Future<void> logout() async {
    final tokenStorage = ref.read(secureTokenStorageProvider);
    final refreshToken = await tokenStorage.readRefreshToken();

    if (refreshToken != null) {
      try {
        await ref.read(authApiProvider).logout(refreshToken);
      } catch (_) {
        // A failed logout transport call must not leave the device appearing
        // authenticated: local state is cleared unconditionally below.
      }
    }

    await _clearLocalSession();
  }

  /// Invoked by AuthInterceptor when a refresh attempt fails.
  Future<void> invalidateSession() async {
    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() async {
    await ref.read(secureTokenStorageProvider).clear();
    await ref.read(appPreferencesProvider).clearCachedUser();
    await ref.read(appPreferencesProvider).clearSelectedOrganizationId();
    ref.read(organizationContextControllerProvider.notifier).reset();
    state = const AuthSessionState.unauthenticated();
  }
}

final authSessionControllerProvider = NotifierProvider<AuthSessionController, AuthSessionState>(
  AuthSessionController.new,
);
