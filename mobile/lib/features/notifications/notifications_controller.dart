import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'notification_models.dart';

enum NotificationsLoadStatus { idle, loading, loaded, error }

class NotificationsState {
  const NotificationsState({
    required this.status,
    required this.notifications,
    required this.nextCursor,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.markingAllRead,
    required this.clearingRead,
    required this.pendingMarkReadIds,
  });

  factory NotificationsState.idle() => const NotificationsState(
    status: NotificationsLoadStatus.idle,
    notifications: [],
    nextCursor: null,
    isLoadingMore: false,
    errorMessage: null,
    markingAllRead: false,
    clearingRead: false,
    pendingMarkReadIds: {},
  );

  final NotificationsLoadStatus status;
  final List<AppNotification> notifications;
  final String? nextCursor;
  final bool isLoadingMore;
  final String? errorMessage;

  /// Duplicate-mutation guards: prevent a second Mark All Read/Clear
  /// Read/Mark One Read submission for the same target while one is
  /// already in flight.
  final bool markingAllRead;
  final bool clearingRead;
  final Set<String> pendingMarkReadIds;

  bool get hasMore => nextCursor != null;

  NotificationsState copyWith({
    NotificationsLoadStatus? status,
    List<AppNotification>? notifications,
    String? Function()? nextCursor,
    bool? isLoadingMore,
    String? Function()? errorMessage,
    bool? markingAllRead,
    bool? clearingRead,
    Set<String>? pendingMarkReadIds,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      markingAllRead: markingAllRead ?? this.markingAllRead,
      clearingRead: clearingRead ?? this.clearingRead,
      pendingMarkReadIds: pendingMarkReadIds ?? this.pendingMarkReadIds,
    );
  }
}

const _pageLimit = 20;

/// Owns the Notifications list + mutation lifecycle for the active
/// organization. Structurally identical to EventsListController/
/// PeopleDirectoryController: build() watches
/// organizationContextControllerProvider, so Riverpod tears down and
/// recreates this entire instance on organization switch — an
/// Organization A list/error/pending-mutation state is never carried into
/// Organization B's fresh instance. A generation counter guards the list
/// load/refresh/pagination against races within one instance.
class NotificationsController extends Notifier<NotificationsState> {
  int _generation = 0;
  String? _organizationId;

  @override
  NotificationsState build() {
    final organizationContext = ref.watch(organizationContextControllerProvider);

    if (organizationContext is! OrganizationContextActive) {
      _organizationId = null;
      return NotificationsState.idle();
    }

    _organizationId = organizationContext.selectedOrganizationId;
    final generation = ++_generation;
    Future.microtask(() => _loadFirstPage(generation: generation));

    return NotificationsState.idle();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    await _loadFirstPage(generation: generation);
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.status != NotificationsLoadStatus.loaded) return;

    final organizationId = _organizationId;
    final cursor = state.nextCursor;
    if (organizationId == null || cursor == null) return;

    final generation = _generation;
    state = state.copyWith(isLoadingMore: true);

    try {
      final page = await ref
          .read(notificationsApiProvider)
          .list(organizationId: organizationId, cursor: cursor, limit: _pageLimit);

      if (!ref.mounted || generation != _generation) return;

      final existingIds = state.notifications.map((n) => n.id).toSet();
      final newOnes = page.notifications.where((n) => !existingIds.contains(n.id));

      state = state.copyWith(
        notifications: [...state.notifications, ...newOnes],
        nextCursor: () => page.nextCursor,
        isLoadingMore: false,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _loadFirstPage({required int generation}) async {
    final organizationId = _organizationId;
    if (organizationId == null) return;

    state = state.copyWith(
      status: NotificationsLoadStatus.loading,
      notifications: [],
      nextCursor: () => null,
      isLoadingMore: false,
      errorMessage: () => null,
    );

    try {
      final page = await ref.read(notificationsApiProvider).list(organizationId: organizationId, limit: _pageLimit);

      if (!ref.mounted || generation != _generation) return;

      state = state.copyWith(
        status: NotificationsLoadStatus.loaded,
        notifications: page.notifications,
        nextCursor: () => page.nextCursor,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(status: NotificationsLoadStatus.error, errorMessage: () => error.toString());
    }
  }

  /// Marks exactly one notification read. Duplicate-submission-safe: a
  /// second call for the same id while the first is still in flight is a
  /// no-op. Updates the matching item in place using the real API
  /// response — never a fabricated/optimistic value.
  Future<void> markRead(String notificationId) async {
    final organizationId = _organizationId;
    if (organizationId == null) return;
    if (state.pendingMarkReadIds.contains(notificationId)) return;

    final generation = _generation;
    state = state.copyWith(pendingMarkReadIds: {...state.pendingMarkReadIds, notificationId});

    try {
      final updated = await ref.read(notificationsApiProvider).markRead(
        organizationId: organizationId,
        notificationId: notificationId,
      );

      if (!ref.mounted || generation != _generation) return;

      state = state.copyWith(
        notifications: [
          for (final n in state.notifications)
            if (n.id == notificationId) updated else n,
        ],
        pendingMarkReadIds: {...state.pendingMarkReadIds}..remove(notificationId),
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(pendingMarkReadIds: {...state.pendingMarkReadIds}..remove(notificationId));
    }
  }

  /// Duplicate-submission-safe. Real post-mutation refresh — never locally
  /// fabricates the resulting list.
  Future<void> markAllRead() async {
    final organizationId = _organizationId;
    if (organizationId == null || state.markingAllRead) return;

    final generation = _generation;
    state = state.copyWith(markingAllRead: true);

    try {
      await ref.read(notificationsApiProvider).markAllRead(organizationId: organizationId);
      if (!ref.mounted || generation != _generation) return;
      await _loadFirstPage(generation: generation);
    } finally {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(markingAllRead: false);
      }
    }
  }

  /// Duplicate-submission-safe. Real post-mutation refresh — never locally
  /// fabricates the resulting list.
  Future<void> clearRead() async {
    final organizationId = _organizationId;
    if (organizationId == null || state.clearingRead) return;

    final generation = _generation;
    state = state.copyWith(clearingRead: true);

    try {
      await ref.read(notificationsApiProvider).clearRead(organizationId: organizationId);
      if (!ref.mounted || generation != _generation) return;
      await _loadFirstPage(generation: generation);
    } finally {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(clearingRead: false);
      }
    }
  }
}

final notificationsControllerProvider = NotifierProvider<NotificationsController, NotificationsState>(
  NotificationsController.new,
);
