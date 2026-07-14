import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'event_models.dart';

/// UI-only tab selection matching the frozen Events List's All/Upcoming/
/// Today/Completed/Cancelled tabs. Unlike [PeopleStatusFilter], none of
/// these has a backend query parameter — Task 061 confirmed there is no
/// server-side lifecycle filter — so this is always applied client-side
/// over whatever page(s) have already been fetched via search/category.
enum EventLifecycleFilter {
  all,
  upcoming,
  today,
  completed,
  cancelled;

  bool matches(EventLifecycleStatus status) {
    switch (this) {
      case EventLifecycleFilter.all:
        return true;
      case EventLifecycleFilter.upcoming:
        return status == EventLifecycleStatus.upcoming;
      case EventLifecycleFilter.today:
        return status == EventLifecycleStatus.today;
      case EventLifecycleFilter.completed:
        return status == EventLifecycleStatus.completed;
      case EventLifecycleFilter.cancelled:
        return status == EventLifecycleStatus.cancelled;
    }
  }
}

enum EventsLoadStatus { idle, loading, loaded, error }

class EventsListState {
  const EventsListState({
    required this.status,
    required this.events,
    required this.nextCursor,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.search,
    required this.category,
    required this.lifecycleFilter,
  });

  factory EventsListState.idle() => const EventsListState(
    status: EventsLoadStatus.idle,
    events: [],
    nextCursor: null,
    isLoadingMore: false,
    errorMessage: null,
    search: '',
    category: '',
    lifecycleFilter: EventLifecycleFilter.all,
  );

  final EventsLoadStatus status;
  final List<EventSummary> events;
  final String? nextCursor;
  final bool isLoadingMore;
  final String? errorMessage;
  final String search;
  final String category;
  final EventLifecycleFilter lifecycleFilter;

  bool get hasMore => nextCursor != null;

  List<EventSummary> get visibleEvents =>
      events.where((event) => lifecycleFilter.matches(deriveEventLifecycleStatus(event))).toList();

  EventsListState copyWith({
    EventsLoadStatus? status,
    List<EventSummary>? events,
    String? Function()? nextCursor,
    bool? isLoadingMore,
    String? Function()? errorMessage,
    String? search,
    String? category,
    EventLifecycleFilter? lifecycleFilter,
  }) {
    return EventsListState(
      status: status ?? this.status,
      events: events ?? this.events,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      search: search ?? this.search,
      category: category ?? this.category,
      lifecycleFilter: lifecycleFilter ?? this.lifecycleFilter,
    );
  }
}

const _searchDebounce = Duration(milliseconds: 350);
const _pageLimit = 20;

/// Owns the Events List data lifecycle for the active organization.
/// Structurally identical to PeopleDirectoryController: build() watches
/// organizationContextControllerProvider, so Riverpod tears down and
/// recreates this entire instance on organization switch — Organization
/// A's list/cursor/search/filter/error state is never carried into
/// Organization B's fresh instance. A generation counter guards against
/// races between search/category/pagination requests within one instance.
class EventsListController extends Notifier<EventsListState> {
  Timer? _debounce;
  int _generation = 0;
  String? _organizationId;

  @override
  EventsListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });

    final organizationContext = ref.watch(organizationContextControllerProvider);

    if (organizationContext is! OrganizationContextActive) {
      _organizationId = null;
      return EventsListState.idle();
    }

    _organizationId = organizationContext.selectedOrganizationId;
    final generation = ++_generation;
    Future.microtask(() => _loadFirstPage(generation: generation, search: '', category: ''));

    return EventsListState.idle();
  }

  void updateSearch(String rawValue) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      final trimmed = rawValue.trim();
      if (trimmed == state.search) return;
      final generation = ++_generation;
      _loadFirstPage(generation: generation, search: trimmed, category: state.category);
    });
  }

  void updateCategory(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed == state.category) return;
    final generation = ++_generation;
    _loadFirstPage(generation: generation, search: state.search, category: trimmed);
  }

  void updateLifecycleFilter(EventLifecycleFilter filter) {
    if (filter == state.lifecycleFilter) return;
    state = state.copyWith(lifecycleFilter: filter);
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    await _loadFirstPage(generation: generation, search: state.search, category: state.category);
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.status != EventsLoadStatus.loaded) return;

    final organizationId = _organizationId;
    final cursor = state.nextCursor;
    if (organizationId == null || cursor == null) return;

    final generation = _generation;
    state = state.copyWith(isLoadingMore: true);

    try {
      final page = await ref.read(eventsApiProvider).list(
        organizationId: organizationId,
        cursor: cursor,
        search: state.search.isEmpty ? null : state.search,
        category: state.category.isEmpty ? null : state.category,
        limit: _pageLimit,
      );

      if (!ref.mounted || generation != _generation) return;

      final existingIds = state.events.map((event) => event.id).toSet();
      final newEvents = page.events.where((event) => !existingIds.contains(event.id));

      state = state.copyWith(
        events: [...state.events, ...newEvents],
        nextCursor: () => page.nextCursor,
        isLoadingMore: false,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _loadFirstPage({required int generation, required String search, required String category}) async {
    final organizationId = _organizationId;
    if (organizationId == null) return;

    state = state.copyWith(
      status: EventsLoadStatus.loading,
      events: [],
      nextCursor: () => null,
      isLoadingMore: false,
      errorMessage: () => null,
      search: search,
      category: category,
    );

    try {
      final page = await ref.read(eventsApiProvider).list(
        organizationId: organizationId,
        search: search.isEmpty ? null : search,
        category: category.isEmpty ? null : category,
        limit: _pageLimit,
      );

      if (!ref.mounted || generation != _generation) return;

      state = state.copyWith(status: EventsLoadStatus.loaded, events: page.events, nextCursor: () => page.nextCursor);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(status: EventsLoadStatus.error, errorMessage: () => error.toString());
    }
  }
}

final eventsListControllerProvider = NotifierProvider<EventsListController, EventsListState>(
  EventsListController.new,
);
