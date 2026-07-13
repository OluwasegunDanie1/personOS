import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'person_profile_controller.dart';

enum CreateFollowUpSubmitStatus { idle, submitting, success, error }

class CreateFollowUpState {
  const CreateFollowUpState({required this.status, required this.errorMessage, required this.shouldClose});

  factory CreateFollowUpState.idle() =>
      const CreateFollowUpState(status: CreateFollowUpSubmitStatus.idle, errorMessage: null, shouldClose: false);

  final CreateFollowUpSubmitStatus status;
  final String? errorMessage;

  /// Set when the active organization changed away from the organization
  /// this form was opened for — mirrors AddPersonController.shouldClose
  /// exactly. The screen must pop without showing any success/error UI.
  final bool shouldClose;

  CreateFollowUpState copyWith({
    CreateFollowUpSubmitStatus? status,
    String? Function()? errorMessage,
    bool? shouldClose,
  }) {
    return CreateFollowUpState(
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      shouldClose: shouldClose ?? this.shouldClose,
    );
  }
}

/// Owns the Create Follow-up submit lifecycle for exactly one (personId,
/// opening-organization) pair. Structurally identical to AddPersonController:
/// the opening organization is captured once (ref.read) at build() time; a
/// ref.listen on organizationContextControllerProvider sets [shouldClose]
/// once the active organization stops matching; every submit captures a
/// generation, and a response is only applied if ref.mounted, the
/// generation is still current, and the organization is still the opening
/// one — so a stale Organization-A success/error can never surface after
/// Organization B is selected.
///
/// On success, this controller does not fabricate a locally-constructed
/// Follow-up as authoritative state: it calls the already-mounted
/// PersonProfileController's own refreshFollowUps(), which performs the real
/// GET request that remains the sole authority for the displayed collection.
class CreateFollowUpController extends Notifier<CreateFollowUpState> {
  CreateFollowUpController(this.personId);

  final String personId;

  late final String openingOrganizationId;
  int _generation = 0;

  @override
  CreateFollowUpState build() {
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

    return CreateFollowUpState.idle();
  }

  /// Explicit, testable invalidation for Cancel/back — any in-flight
  /// submit's eventual response becomes a no-op once this is called.
  void cancel() {
    _generation++;
  }

  bool _isCurrent(int generation) {
    if (!ref.mounted || generation != _generation) return false;
    final organizationContext = ref.read(organizationContextControllerProvider);
    return organizationContext is OrganizationContextActive &&
        organizationContext.selectedOrganizationId == openingOrganizationId;
  }

  Future<void> submit({required String title, String? description, DateTime? dueDate}) async {
    if (state.status == CreateFollowUpSubmitStatus.submitting) return;
    if (openingOrganizationId.isEmpty) return;

    final generation = ++_generation;
    state = state.copyWith(status: CreateFollowUpSubmitStatus.submitting, errorMessage: () => null);

    try {
      await ref
          .read(peopleApiProvider)
          .createFollowUp(
            organizationId: openingOrganizationId,
            personId: personId,
            title: title,
            description: description,
            dueDate: dueDate,
          );

      if (!_isCurrent(generation)) return;

      // The real GET refresh remains the sole displayed-collection authority
      // — the POST response above is validated but never appended locally.
      await ref.read(personProfileControllerProvider(personId).notifier).refreshFollowUps();

      if (!_isCurrent(generation)) return;

      state = state.copyWith(status: CreateFollowUpSubmitStatus.success);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(status: CreateFollowUpSubmitStatus.error, errorMessage: () => error.toString());
    }
  }
}

final createFollowUpControllerProvider = NotifierProvider.family.autoDispose<
  CreateFollowUpController,
  CreateFollowUpState,
  String
>(CreateFollowUpController.new);
