import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import '../people/people_models.dart';
import 'events_provider.dart';

enum PeopleSearchStatus { idle, loading, loaded, error }

class EventCheckInState {
  const EventCheckInState({
    required this.status,
    required this.people,
    required this.nextCursor,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.search,
    required this.pendingPersonIds,
    required this.checkedInPersonIds,
    required this.checkInErrorMessage,
  });

  factory EventCheckInState.idle() => const EventCheckInState(
    status: PeopleSearchStatus.idle,
    people: [],
    nextCursor: null,
    isLoadingMore: false,
    errorMessage: null,
    search: '',
    pendingPersonIds: {},
    checkedInPersonIds: {},
    checkInErrorMessage: null,
  );

  final PeopleSearchStatus status;
  final List<PersonSummary> people;
  final String? nextCursor;
  final bool isLoadingMore;
  final String? errorMessage;
  final String search;

  /// Duplicate-submission guard: a personId currently mid-request.
  final Set<String> pendingPersonIds;

  /// Real personIds confirmed checked in during this session (from an
  /// actual server response — either a fresh 201 or an idempotent-replay
  /// 200 both confirm the person IS checked in). Never fabricated; merged
  /// by the screen with the real eventAttendanceProvider list to also
  /// reflect check-ins from before this session started.
  final Set<String> checkedInPersonIds;

  final String? checkInErrorMessage;

  bool get hasMore => nextCursor != null;

  EventCheckInState copyWith({
    PeopleSearchStatus? status,
    List<PersonSummary>? people,
    String? Function()? nextCursor,
    bool? isLoadingMore,
    String? Function()? errorMessage,
    String? search,
    Set<String>? pendingPersonIds,
    Set<String>? checkedInPersonIds,
    String? Function()? checkInErrorMessage,
  }) {
    return EventCheckInState(
      status: status ?? this.status,
      people: people ?? this.people,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      search: search ?? this.search,
      pendingPersonIds: pendingPersonIds ?? this.pendingPersonIds,
      checkedInPersonIds: checkedInPersonIds ?? this.checkedInPersonIds,
      checkInErrorMessage: checkInErrorMessage != null ? checkInErrorMessage() : this.checkInErrorMessage,
    );
  }
}

const _searchDebounce = Duration(milliseconds: 350);
const _pageLimit = 20;

/// Owns the Event Check-In screen's People search/pagination and the
/// check-in submission lifecycle for exactly one eventId. Structurally
/// mirrors PeopleDirectoryController: build() watches
/// organizationContextControllerProvider, so Riverpod tears down and
/// recreates this entire instance on organization switch — no People or
/// Attendance state ever survives across organizations. A generation
/// counter guards the search/pagination against races; a separate
/// per-person pending set guards check-in submissions against duplicates
/// without blocking check-ins for other people.
///
/// Only real, active People in the current organization are searched
/// (status: ACTIVE) — no capacity/RSVP/guest/expected-attendee concept.
/// Every check-in call records the backend's own default status; there is
/// no status picker. On success (created or idempotent replay alike),
/// this controller invalidates the shared eventAttendanceProvider(eventId)
/// so the real Event Attendance list reflects it — it never locally
/// fabricates an Attendance row.
class EventCheckInController extends Notifier<EventCheckInState> {
  EventCheckInController(this.eventId);

  final String eventId;

  Timer? _debounce;
  int _generation = 0;
  String? _organizationId;

  @override
  EventCheckInState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });

    final organizationContext = ref.watch(organizationContextControllerProvider);

    if (organizationContext is! OrganizationContextActive) {
      _organizationId = null;
      return EventCheckInState.idle();
    }

    _organizationId = organizationContext.selectedOrganizationId;
    final generation = ++_generation;
    Future.microtask(() => _loadFirstPage(generation: generation, search: ''));

    return EventCheckInState.idle();
  }

  void updateSearch(String rawValue) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      final trimmed = rawValue.trim();
      if (trimmed == state.search) return;
      final generation = ++_generation;
      _loadFirstPage(generation: generation, search: trimmed);
    });
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    await _loadFirstPage(generation: generation, search: state.search);
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.status != PeopleSearchStatus.loaded) return;

    final organizationId = _organizationId;
    final cursor = state.nextCursor;
    if (organizationId == null || cursor == null) return;

    final generation = _generation;
    state = state.copyWith(isLoadingMore: true);

    try {
      final page = await ref.read(peopleApiProvider).list(
        organizationId: organizationId,
        cursor: cursor,
        search: state.search.isEmpty ? null : state.search,
        status: PersonStatus.active,
        limit: _pageLimit,
      );

      if (!ref.mounted || generation != _generation) return;

      final existingIds = state.people.map((p) => p.id).toSet();
      final newOnes = page.people.where((p) => !existingIds.contains(p.id));

      state = state.copyWith(
        people: [...state.people, ...newOnes],
        nextCursor: () => page.nextCursor,
        isLoadingMore: false,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _loadFirstPage({required int generation, required String search}) async {
    final organizationId = _organizationId;
    if (organizationId == null) return;

    state = state.copyWith(
      status: PeopleSearchStatus.loading,
      people: [],
      nextCursor: () => null,
      isLoadingMore: false,
      errorMessage: () => null,
      search: search,
    );

    try {
      final page = await ref.read(peopleApiProvider).list(
        organizationId: organizationId,
        search: search.isEmpty ? null : search,
        status: PersonStatus.active,
        limit: _pageLimit,
      );

      if (!ref.mounted || generation != _generation) return;

      state = state.copyWith(status: PeopleSearchStatus.loaded, people: page.people, nextCursor: () => page.nextCursor);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(status: PeopleSearchStatus.error, errorMessage: () => error.toString());
    }
  }

  /// Duplicate-submission-safe per personId: a second tap for the same
  /// person while the first request is in flight is a no-op; check-ins for
  /// other people remain unaffected.
  Future<void> checkIn(String personId) async {
    final organizationId = _organizationId;
    if (organizationId == null) return;
    if (state.pendingPersonIds.contains(personId)) return;

    final generation = _generation;
    state = state.copyWith(
      pendingPersonIds: {...state.pendingPersonIds, personId},
      checkInErrorMessage: () => null,
    );

    try {
      await ref.read(eventsApiProvider).recordAttendance(
        organizationId: organizationId,
        eventId: eventId,
        personId: personId,
      );

      if (!ref.mounted || generation != _generation) return;

      // The real GET Attendance refresh remains the sole Attendance-list
      // authority — the POST response above is validated but never
      // appended/fabricated locally beyond this session's own checkmark.
      ref.invalidate(eventAttendanceProvider(eventId));

      state = state.copyWith(
        pendingPersonIds: {...state.pendingPersonIds}..remove(personId),
        checkedInPersonIds: {...state.checkedInPersonIds, personId},
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        pendingPersonIds: {...state.pendingPersonIds}..remove(personId),
        checkInErrorMessage: () => error.toString(),
      );
    }
  }
}

final eventCheckInControllerProvider = NotifierProvider.family.autoDispose<
  EventCheckInController,
  EventCheckInState,
  String
>(EventCheckInController.new);
