import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'event_models.dart';

/// Refetches whenever the active organization changes, since
/// organizationContextControllerProvider is watched rather than read —
/// exactly the same staleness-safety mechanism dashboardSummaryProvider
/// already establishes.
final eventDetailProvider = FutureProvider.family.autoDispose<EventDetail, String>((ref, eventId) async {
  final contextState = ref.watch(organizationContextControllerProvider);

  if (contextState is! OrganizationContextActive) {
    throw StateError('No active organization context');
  }

  return ref.read(eventsApiProvider).detail(organizationId: contextState.selectedOrganizationId, eventId: eventId);
});

/// Read-only, single bounded first page (mirrors
/// PersonProfileController's Upcoming Follow-ups precedent: no fabricated
/// total, no recursive nextCursor following — a "more exist" note is used
/// instead when hasMore is true).
final eventAttendanceProvider = FutureProvider.family.autoDispose<EventAttendanceListResult, String>((
  ref,
  eventId,
) async {
  final contextState = ref.watch(organizationContextControllerProvider);

  if (contextState is! OrganizationContextActive) {
    throw StateError('No active organization context');
  }

  return ref.read(eventsApiProvider).attendance(organizationId: contextState.selectedOrganizationId, eventId: eventId);
});
