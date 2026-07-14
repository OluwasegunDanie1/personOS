import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import '../organizations/organization_models.dart';

/// Mirrors dashboard_provider.dart's/organization_members_provider.dart's
/// established convention: watches the active organization context so
/// Riverpod's own dependency invalidation discards a stale Organization A
/// response after switching to Organization B — no manual generation
/// counter needed for this simple, single-fetch, no-mutation read screen
/// (Product Task 052). Each RoleSummary's own `permissions` field already
/// carries the real, embedded RolePermission-join data (Product Task 050),
/// so this alone fully supports the frozen "select a role, see its real
/// permissions" composition without a second request to the separate flat
/// GET .../permissions endpoint.
final organizationRolesProvider = FutureProvider.autoDispose<List<RoleSummary>>((ref) async {
  final contextState = ref.watch(organizationContextControllerProvider);

  if (contextState is! OrganizationContextActive) {
    throw StateError('No active organization context');
  }

  return ref.read(organizationsApiProvider).listRoles(contextState.selectedOrganizationId);
});
