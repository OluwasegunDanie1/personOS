import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'events_list_controller.dart';

enum CreateEventSubmitStatus { idle, submitting, success, error }

class CreateEventState {
  const CreateEventState({required this.status, required this.errorMessage, required this.shouldClose});

  factory CreateEventState.idle() =>
      const CreateEventState(status: CreateEventSubmitStatus.idle, errorMessage: null, shouldClose: false);

  final CreateEventSubmitStatus status;
  final String? errorMessage;

  /// Set when the active organization changed away from the organization
  /// this form was opened for — mirrors AddPersonController/
  /// CreateFollowUpController's shouldClose exactly.
  final bool shouldClose;

  CreateEventState copyWith({CreateEventSubmitStatus? status, String? Function()? errorMessage, bool? shouldClose}) {
    return CreateEventState(
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      shouldClose: shouldClose ?? this.shouldClose,
    );
  }
}

/// Owns the Create Event submit lifecycle for exactly one opening-
/// organization. Structurally identical to CreateFollowUpController: the
/// opening organization is captured once (ref.read) at build() time; a
/// ref.listen on organizationContextControllerProvider sets [shouldClose]
/// once the active organization stops matching; every submit captures a
/// generation, and a response is only applied if ref.mounted, the
/// generation is still current, and the organization is still the opening
/// one.
///
/// On success, this controller does not fabricate a locally-constructed
/// Event as authoritative state: it calls the already-mounted Events List
/// controller's own refresh(), which performs the real GET request that
/// remains the sole authority for the displayed collection.
class CreateEventController extends Notifier<CreateEventState> {
  late final String openingOrganizationId;
  int _generation = 0;

  @override
  CreateEventState build() {
    final organizationContext = ref.read(organizationContextControllerProvider);
    openingOrganizationId = organizationContext is OrganizationContextActive
        ? organizationContext.selectedOrganizationId
        : '';

    ref.listen(organizationContextControllerProvider, (previous, next) {
      final stillOpeningOrganization =
          next is OrganizationContextActive && next.selectedOrganizationId == openingOrganizationId;
      if (!stillOpeningOrganization) {
        _generation++;
        state = state.copyWith(shouldClose: true);
      }
    });

    return CreateEventState.idle();
  }

  /// Explicit, testable invalidation for Cancel/back.
  void cancel() {
    _generation++;
  }

  bool _isCurrent(int generation) {
    if (!ref.mounted || generation != _generation) return false;
    final organizationContext = ref.read(organizationContextControllerProvider);
    return organizationContext is OrganizationContextActive &&
        organizationContext.selectedOrganizationId == openingOrganizationId;
  }

  /// [startDate] must already be a fully-resolved local DateTime combined
  /// from the user's own explicitly selected Date AND Start Time — never
  /// defaulted here. [endDate], when non-null, is the same for the optional
  /// End Time.
  Future<void> submit({
    required String title,
    String? category,
    String? description,
    String? venue,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    if (state.status == CreateEventSubmitStatus.submitting) return;
    if (openingOrganizationId.isEmpty) return;

    final generation = ++_generation;
    state = state.copyWith(status: CreateEventSubmitStatus.submitting, errorMessage: () => null);

    try {
      await ref
          .read(eventsApiProvider)
          .create(
            organizationId: openingOrganizationId,
            title: title,
            category: category,
            description: description,
            venue: venue,
            startDate: startDate,
            endDate: endDate,
          );

      if (!_isCurrent(generation)) return;

      // The real GET refresh remains the sole displayed-collection authority
      // — the POST response above is validated but never appended locally.
      await ref.read(eventsListControllerProvider.notifier).refresh();

      if (!_isCurrent(generation)) return;

      state = state.copyWith(status: CreateEventSubmitStatus.success);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(status: CreateEventSubmitStatus.error, errorMessage: () => error.toString());
    }
  }
}

final createEventControllerProvider = NotifierProvider.autoDispose<CreateEventController, CreateEventState>(
  CreateEventController.new,
);
