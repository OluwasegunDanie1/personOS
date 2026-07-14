import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import '../organizations/organization_models.dart';

/// Mirrors dashboard_provider.dart's established convention exactly: a
/// FutureProvider that watches (not reads) the active organization context,
/// so it automatically re-executes on organization switch. Riverpod's own
/// dependency-invalidation guarantees a stale Organization A response can
/// never overwrite Organization B's data once the watched context changes —
/// no manual generation counter is needed for this simple, single-fetch,
/// no-mutation read screen (Product Task 052).
final organizationMembersProvider = FutureProvider.autoDispose<List<OrganizationMemberSummary>>((ref) async {
  final contextState = ref.watch(organizationContextControllerProvider);

  if (contextState is! OrganizationContextActive) {
    throw StateError('No active organization context');
  }

  return ref.read(organizationsApiProvider).listMembers(contextState.selectedOrganizationId);
});
