import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'people_models.dart';

/// UI-only filter selection. Distinct from [PersonStatus] (the API-mirrored
/// model field): "all" has no backend representation — it means "omit the
/// status query parameter" and is never sent to the API.
enum PeopleStatusFilter {
  all,
  active,
  inactive;

  PersonStatus? toApiStatus() {
    switch (this) {
      case PeopleStatusFilter.all:
        return null;
      case PeopleStatusFilter.active:
        return PersonStatus.active;
      case PeopleStatusFilter.inactive:
        return PersonStatus.inactive;
    }
  }
}

enum PeopleLoadStatus { idle, loading, loaded, error }

class PeopleDirectoryState {
  const PeopleDirectoryState({
    required this.status,
    required this.people,
    required this.nextCursor,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.search,
    required this.statusFilter,
  });

  factory PeopleDirectoryState.idle() => const PeopleDirectoryState(
    status: PeopleLoadStatus.idle,
    people: [],
    nextCursor: null,
    isLoadingMore: false,
    errorMessage: null,
    search: '',
    statusFilter: PeopleStatusFilter.all,
  );

  final PeopleLoadStatus status;
  final List<PersonSummary> people;
  final String? nextCursor;
  final bool isLoadingMore;
  final String? errorMessage;
  final String search;
  final PeopleStatusFilter statusFilter;

  bool get hasMore => nextCursor != null;

  PeopleDirectoryState copyWith({
    PeopleLoadStatus? status,
    List<PersonSummary>? people,
    String? Function()? nextCursor,
    bool? isLoadingMore,
    String? Function()? errorMessage,
    String? search,
    PeopleStatusFilter? statusFilter,
  }) {
    return PeopleDirectoryState(
      status: status ?? this.status,
      people: people ?? this.people,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      search: search ?? this.search,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

const _searchDebounce = Duration(milliseconds: 350);
const _pageLimit = 20;

/// Owns the People Directory data lifecycle for the active organization.
///
/// Organization-switch isolation: this Notifier's build() watches
/// organizationContextControllerProvider, so Riverpod tears down and
/// recreates this entire instance whenever the selected organization
/// changes — Organization A's list/cursor/search/filter/error state is
/// never carried into Organization B's fresh instance.
///
/// Within a single instance, search/filter/pagination changes cannot
/// dispose the instance, so an explicit generation counter guards against
/// races between them: any in-flight request captures the generation at
/// request time, and its result is discarded (via ref.mounted and a
/// generation-mismatch check) if a newer request has since started.
class PeopleDirectoryController extends Notifier<PeopleDirectoryState> {
  Timer? _debounce;
  int _generation = 0;
  String? _organizationId;

  @override
  PeopleDirectoryState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });

    final organizationContext = ref.watch(organizationContextControllerProvider);

    if (organizationContext is! OrganizationContextActive) {
      _organizationId = null;
      return PeopleDirectoryState.idle();
    }

    _organizationId = organizationContext.selectedOrganizationId;
    final generation = ++_generation;
    Future.microtask(
      () => _loadFirstPage(generation: generation, search: '', statusFilter: PeopleStatusFilter.all),
    );

    return PeopleDirectoryState.idle();
  }

  void updateSearch(String rawValue) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      final trimmed = rawValue.trim();
      if (trimmed == state.search) return;
      final generation = ++_generation;
      _loadFirstPage(generation: generation, search: trimmed, statusFilter: state.statusFilter);
    });
  }

  void updateStatusFilter(PeopleStatusFilter filter) {
    if (filter == state.statusFilter) return;
    final generation = ++_generation;
    _loadFirstPage(generation: generation, search: state.search, statusFilter: filter);
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    await _loadFirstPage(generation: generation, search: state.search, statusFilter: state.statusFilter);
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.status != PeopleLoadStatus.loaded) return;

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
        status: state.statusFilter.toApiStatus(),
        limit: _pageLimit,
      );

      if (!ref.mounted || generation != _generation) return;

      final existingIds = state.people.map((person) => person.id).toSet();
      final newPeople = page.people.where((person) => !existingIds.contains(person.id));

      state = state.copyWith(
        people: [...state.people, ...newPeople],
        nextCursor: () => page.nextCursor,
        isLoadingMore: false,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _loadFirstPage({
    required int generation,
    required String search,
    required PeopleStatusFilter statusFilter,
  }) async {
    final organizationId = _organizationId;
    if (organizationId == null) return;

    state = state.copyWith(
      status: PeopleLoadStatus.loading,
      people: [],
      nextCursor: () => null,
      isLoadingMore: false,
      errorMessage: () => null,
      search: search,
      statusFilter: statusFilter,
    );

    try {
      final page = await ref.read(peopleApiProvider).list(
        organizationId: organizationId,
        search: search.isEmpty ? null : search,
        status: statusFilter.toApiStatus(),
        limit: _pageLimit,
      );

      if (!ref.mounted || generation != _generation) return;

      state = state.copyWith(status: PeopleLoadStatus.loaded, people: page.people, nextCursor: () => page.nextCursor);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(status: PeopleLoadStatus.error, errorMessage: () => error.toString());
    }
  }
}

final peopleDirectoryControllerProvider = NotifierProvider<PeopleDirectoryController, PeopleDirectoryState>(
  PeopleDirectoryController.new,
);
