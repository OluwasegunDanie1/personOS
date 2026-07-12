import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'organization_models.dart';

sealed class OrganizationContextState {
  const OrganizationContextState();
}

class OrganizationContextRestoring extends OrganizationContextState {
  const OrganizationContextRestoring();
}

class OrganizationContextEmpty extends OrganizationContextState {
  const OrganizationContextEmpty();
}

class OrganizationContextFailure extends OrganizationContextState {
  const OrganizationContextFailure(this.message);
  final String message;
}

class OrganizationContextActive extends OrganizationContextState {
  const OrganizationContextActive({required this.organizations, required this.selectedOrganizationId});

  final List<OrganizationSummary> organizations;
  final String selectedOrganizationId;

  OrganizationSummary get selected => organizations.firstWhere((o) => o.id == selectedOrganizationId);
}

/// Organization context is client-side-only (16_Security.md's Organization
/// Context Mechanism): there is no server-side active-organization session
/// and no switch endpoint. This controller restores membership context from
/// GET /organizations and validates/persists the selected organizationId
/// locally only.
class OrganizationContextController extends Notifier<OrganizationContextState> {
  @override
  OrganizationContextState build() => const OrganizationContextRestoring();

  Future<void> restore() async {
    state = const OrganizationContextRestoring();

    try {
      final organizations = await ref.read(organizationsApiProvider).list();
      final preferences = ref.read(appPreferencesProvider);

      if (organizations.isEmpty) {
        await preferences.clearSelectedOrganizationId();
        state = const OrganizationContextEmpty();
        return;
      }

      final persistedId = await preferences.readSelectedOrganizationId();
      final persistedStillValid = persistedId != null && organizations.any((o) => o.id == persistedId);
      final selectedId = persistedStillValid ? persistedId : organizations.first.id;

      await preferences.saveSelectedOrganizationId(selectedId);
      state = OrganizationContextActive(organizations: organizations, selectedOrganizationId: selectedId);
    } catch (error) {
      state = OrganizationContextFailure(error.toString());
    }
  }

  Future<void> createOrganization(String name) async {
    await ref.read(organizationsApiProvider).create(name);
    await restore();
  }

  /// Client-side-only context change; no backend switch endpoint exists or
  /// is approved.
  Future<void> selectOrganization(String organizationId) async {
    final current = state;
    if (current is! OrganizationContextActive) return;
    if (!current.organizations.any((o) => o.id == organizationId)) return;

    await ref.read(appPreferencesProvider).saveSelectedOrganizationId(organizationId);
    state = OrganizationContextActive(organizations: current.organizations, selectedOrganizationId: organizationId);
  }

  void reset() {
    state = const OrganizationContextRestoring();
  }
}

final organizationContextControllerProvider =
    NotifierProvider<OrganizationContextController, OrganizationContextState>(OrganizationContextController.new);
