import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'people_models.dart';

enum ProfileLoadStatus { loading, loaded, error }

class PersonProfileState {
  const PersonProfileState({
    required this.status,
    required this.detail,
    required this.journey,
    required this.stages,
    required this.attendanceSummary,
    required this.errorMessage,
    required this.shouldClose,
  });

  factory PersonProfileState.initial() => const PersonProfileState(
    status: ProfileLoadStatus.loading,
    detail: null,
    journey: null,
    stages: null,
    attendanceSummary: null,
    errorMessage: null,
    shouldClose: false,
  );

  final ProfileLoadStatus status;
  final PersonDetail? detail;
  final PersonJourneyView? journey;
  final List<JourneyStageListEntry>? stages;
  final AttendanceSummary? attendanceSummary;
  final String? errorMessage;

  /// Set when the active organization changed away from the organization
  /// this Profile was opened for. The screen must close (return to People)
  /// without rendering any of this instance's data once this becomes true —
  /// mirrors AddPersonController.shouldClose exactly.
  final bool shouldClose;

  PersonProfileState copyWith({
    ProfileLoadStatus? status,
    PersonDetail? Function()? detail,
    PersonJourneyView? Function()? journey,
    List<JourneyStageListEntry>? Function()? stages,
    AttendanceSummary? Function()? attendanceSummary,
    String? Function()? errorMessage,
    bool? shouldClose,
  }) {
    return PersonProfileState(
      status: status ?? this.status,
      detail: detail != null ? detail() : this.detail,
      journey: journey != null ? journey() : this.journey,
      stages: stages != null ? stages() : this.stages,
      attendanceSummary: attendanceSummary != null ? attendanceSummary() : this.attendanceSummary,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      shouldClose: shouldClose ?? this.shouldClose,
    );
  }
}

/// Owns the Person Profile data lifecycle for exactly one (personId,
/// opening-organization) pair.
///
/// Family-per-personId: this Notifier is constructed with personId baked in
/// via NotifierProvider.family, so Riverpod creates a fresh instance
/// whenever personId changes and disposes the old one (.autoDispose) — an
/// older personId's in-flight response can never be applied to a newer
/// personId's state, since there is no shared mutable instance across a
/// personId transition.
///
/// Organization pinning + stale-response protection: mirrors
/// AddPersonController exactly. The opening organization is captured once
/// (ref.read, not ref.watch) at build() time. A ref.listen on
/// organizationContextControllerProvider then reacts to *later* changes: if
/// the active organization stops being the opening organization,
/// [PersonProfileState.shouldClose] is set (Profile closes rather than
/// reloading this personId under the new organization, per controller
/// ruling C). Every load captures a generation counter; a response is only
/// applied if ref.mounted is still true, the generation is still current,
/// and the active organization is still the opening organization — the same
/// three-part check AddPersonController uses, so a stale
/// Organization-A success or error can never become authoritative after
/// Organization B is selected (or after a retry supersedes it).
class PersonProfileController extends Notifier<PersonProfileState> {
  PersonProfileController(this.personId);

  final String personId;

  late final String openingOrganizationId;
  int _generation = 0;

  @override
  PersonProfileState build() {
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

    final generation = ++_generation;
    Future.microtask(() => _load(generation: generation));

    return PersonProfileState.initial();
  }

  bool _isCurrent(int generation) {
    if (!ref.mounted || generation != _generation) return false;
    final organizationContext = ref.read(organizationContextControllerProvider);
    return organizationContext is OrganizationContextActive &&
        organizationContext.selectedOrganizationId == openingOrganizationId;
  }

  /// Retries the same (personId, opening-organization) pair. A no-op once
  /// the organization has switched away (shouldClose governs that case).
  Future<void> retry() async {
    if (openingOrganizationId.isEmpty) return;
    final generation = ++_generation;
    state = state.copyWith(status: ProfileLoadStatus.loading, errorMessage: () => null);
    await _load(generation: generation);
  }

  Future<void> _load({required int generation}) async {
    if (openingOrganizationId.isEmpty) return;

    try {
      final api = ref.read(peopleApiProvider);
      final detailFuture = api.detail(organizationId: openingOrganizationId, personId: personId);
      final journeyFuture = api.journey(organizationId: openingOrganizationId, personId: personId);
      final stagesFuture = api.journeyStages(organizationId: openingOrganizationId);
      final summaryFuture = api.attendanceSummary(organizationId: openingOrganizationId, personId: personId);

      final detail = await detailFuture;
      final journey = await journeyFuture;
      final stages = await stagesFuture;
      final summary = await summaryFuture;

      if (!_isCurrent(generation)) return;

      state = state.copyWith(
        status: ProfileLoadStatus.loaded,
        detail: () => detail,
        journey: () => journey,
        stages: () => stages,
        attendanceSummary: () => summary,
        errorMessage: () => null,
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;
      // A failed load (including a retry that follows a prior success)
      // never leaves stale Detail/Journey/Stages/Attendance data sitting in
      // state alongside the error status: all four are explicitly cleared,
      // not merely left unrendered, so nothing here can ever be mistaken
      // for authoritative Profile data after a failure.
      state = state.copyWith(
        status: ProfileLoadStatus.error,
        detail: () => null,
        journey: () => null,
        stages: () => null,
        attendanceSummary: () => null,
        errorMessage: () => error.toString(),
      );
    }
  }
}

final personProfileControllerProvider = NotifierProvider.family.autoDispose<
  PersonProfileController,
  PersonProfileState,
  String
>(PersonProfileController.new);
