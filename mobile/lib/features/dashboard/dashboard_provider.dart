import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'dashboard_models.dart';

/// Refetches whenever the active organization changes, since
/// organizationContextControllerProvider is watched rather than read.
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final contextState = ref.watch(organizationContextControllerProvider);

  if (contextState is! OrganizationContextActive) {
    throw StateError('No active organization context');
  }

  return ref.read(dashboardApiProvider).fetch(contextState.selectedOrganizationId);
});
