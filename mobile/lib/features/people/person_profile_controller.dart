import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'people_models.dart';

enum ProfileLoadStatus { loading, loaded, error }

/// Independent from [ProfileLoadStatus]: a Follow-up list failure/loading
/// state must never replace the whole Profile core (Product Task 043 §3) —
/// only the "Upcoming Follow-ups" region degrades.
enum FollowUpRegionStatus { loading, loaded, error }

class PersonProfileState {
  const PersonProfileState({
    required this.status,
    required this.detail,
    required this.journey,
    required this.stages,
    required this.attendanceSummary,
    required this.errorMessage,
    required this.shouldClose,
    required this.followUpStatus,
    required this.followUps,
    required this.followUpsHasMore,
    required this.followUpErrorMessage,
  });

  factory PersonProfileState.initial() => const PersonProfileState(
    status: ProfileLoadStatus.loading,
    detail: null,
    journey: null,
    stages: null,
    attendanceSummary: null,
    errorMessage: null,
    shouldClose: false,
    followUpStatus: FollowUpRegionStatus.loading,
    followUps: null,
    followUpsHasMore: false,
    followUpErrorMessage: null,
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

  /// "Upcoming Follow-ups" region state — the real, non-completed
  /// (PENDING/IN_PROGRESS) Follow-up records from one bounded person-scoped
  /// page. Never includes COMPLETED records; never an invented UPCOMING
  /// status. Independent of Profile core [status]: a Follow-up failure never
  /// erases Detail/Journey/Stages/AttendanceSummary, and a core failure
  /// simply means this region is never rendered (the whole Profile body is
  /// replaced by the core error state, unchanged existing behavior).
  final FollowUpRegionStatus followUpStatus;
  final List<FollowUpSummary>? followUps;

  /// True when the bounded first page's nextCursor was non-null — the
  /// visible collection must never be presented as an exhaustive total when
  /// this is true (no fabricated "{N} scheduled follow-ups" count).
  final bool followUpsHasMore;
  final String? followUpErrorMessage;

  PersonProfileState copyWith({
    ProfileLoadStatus? status,
    PersonDetail? Function()? detail,
    PersonJourneyView? Function()? journey,
    List<JourneyStageListEntry>? Function()? stages,
    AttendanceSummary? Function()? attendanceSummary,
    String? Function()? errorMessage,
    bool? shouldClose,
    FollowUpRegionStatus? followUpStatus,
    List<FollowUpSummary>? Function()? followUps,
    bool? followUpsHasMore,
    String? Function()? followUpErrorMessage,
  }) {
    return PersonProfileState(
      status: status ?? this.status,
      detail: detail != null ? detail() : this.detail,
      journey: journey != null ? journey() : this.journey,
      stages: stages != null ? stages() : this.stages,
      attendanceSummary: attendanceSummary != null ? attendanceSummary() : this.attendanceSummary,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      shouldClose: shouldClose ?? this.shouldClose,
      followUpStatus: followUpStatus ?? this.followUpStatus,
      followUps: followUps != null ? followUps() : this.followUps,
      followUpsHasMore: followUpsHasMore ?? this.followUpsHasMore,
      followUpErrorMessage: followUpErrorMessage != null ? followUpErrorMessage() : this.followUpErrorMessage,
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

  /// Separate from [_generation] deliberately: a Follow-up-only refresh
  /// (initial load, region retry, or the post-Create refresh) must never
  /// re-trigger a full Detail/Journey/Stages/Attendance reload, and a core
  /// retry must never re-trigger a redundant Follow-up reload. Both counters
  /// are bumped together only by the organization-switch listener below, so
  /// org-switch still invalidates every in-flight request region-wide.
  int _followUpGeneration = 0;

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
        _followUpGeneration++;
        state = state.copyWith(shouldClose: true);
      }
    });

    final generation = ++_generation;
    Future.microtask(() => _load(generation: generation));

    final followUpGeneration = ++_followUpGeneration;
    Future.microtask(() => _loadFollowUps(generation: followUpGeneration));

    return PersonProfileState.initial();
  }

  bool _isCurrent(int generation) {
    if (!ref.mounted || generation != _generation) return false;
    final organizationContext = ref.read(organizationContextControllerProvider);
    return organizationContext is OrganizationContextActive &&
        organizationContext.selectedOrganizationId == openingOrganizationId;
  }

  bool _isFollowUpCurrent(int generation) {
    if (!ref.mounted || generation != _followUpGeneration) return false;
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

  /// Narrow Detail-only refresh (Product Task 047): the real GET refresh a
  /// successful Edit Person PATCH triggers. Reuses the same [_generation]
  /// counter as [_load]/[retry] (Edit can only be entered from an already-
  /// loaded Profile, so there is never a genuinely concurrent initial load
  /// to race against) but — unlike [_load] — touches only [detail]; journey,
  /// stages, attendanceSummary, and the Follow-up region's own state are
  /// left completely untouched, so a successful edit never forces a
  /// redundant Journey/Attendance/Follow-up reload. On failure, the last
  /// known-good [detail] is deliberately left in place rather than cleared
  /// or replaced by locally-edited values — this method never constructs a
  /// PersonDetail itself, only ever applies what the real GET returns.
  Future<void> refreshDetail() async {
    if (openingOrganizationId.isEmpty) return;
    final generation = ++_generation;

    try {
      final detail = await ref
          .read(peopleApiProvider)
          .detail(organizationId: openingOrganizationId, personId: personId);

      if (!_isCurrent(generation)) return;

      state = state.copyWith(detail: () => detail);
    } catch (_) {
      // Deliberately silent: a failed background refresh must not erase a
      // valid, already-rendered Profile, and must not surface the edited
      // (unconfirmed) form values as if they were authoritative.
    }
  }

  /// Region-specific retry/refresh for "Upcoming Follow-ups" only — used both
  /// for a manual retry after a region error and as the real GET refresh a
  /// successful Create Follow-up triggers. Never touches Profile core state.
  Future<void> refreshFollowUps() async {
    if (openingOrganizationId.isEmpty) return;
    final generation = ++_followUpGeneration;
    state = state.copyWith(followUpStatus: FollowUpRegionStatus.loading, followUpErrorMessage: () => null);
    await _loadFollowUps(generation: generation);
  }

  Future<void> _loadFollowUps({required int generation}) async {
    if (openingOrganizationId.isEmpty) return;

    try {
      final result = await ref
          .read(peopleApiProvider)
          .personFollowUps(organizationId: openingOrganizationId, personId: personId);

      if (!_isFollowUpCurrent(generation)) return;

      // Presentation-level exclusion only — never a status query parameter,
      // never an UPCOMING enum value. Real PENDING/IN_PROGRESS records pass
      // through unchanged; real COMPLETED records are excluded from this
      // Profile region only (they still exist and are untouched server-side).
      final visible = result.followUps.where((followUp) => followUp.status != FollowUpStatus.completed).toList();

      state = state.copyWith(
        followUpStatus: FollowUpRegionStatus.loaded,
        followUps: () => visible,
        followUpsHasMore: result.hasMore,
        followUpErrorMessage: () => null,
      );
    } catch (error) {
      if (!_isFollowUpCurrent(generation)) return;
      state = state.copyWith(
        followUpStatus: FollowUpRegionStatus.error,
        followUps: () => null,
        followUpsHasMore: false,
        followUpErrorMessage: () => error.toString(),
      );
    }
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
