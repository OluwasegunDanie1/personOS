import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/relvio_back_button.dart';
import 'notification_models.dart';
import 'notifications_controller.dart';

/// Matches design/ui-reference/11.png's fourth panel ("Notifications")
/// composition, narrowed to real Notification authority (Product Task
/// 064/066): header, a single real newest-first list grouped by real local
/// createdAt day, unread/read visual distinction (real isRead), Mark All
/// Read and Clear Read actions. The frozen All/People/Events/Attendance/
/// Messages/System category tabs are omitted entirely — Notification has
/// no category column, and inventing per-category icons/colors/filters
/// would fabricate authority that does not exist. The header search icon
/// is also omitted — List Notifications has no search query parameter. A
/// notification row never navigates anywhere (no deep-link authority);
/// tapping an unread row only marks it read, a real, non-navigating action.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  RelvioBackButton(onPressed: () => _back(context)),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    key: const Key('notificationsMarkAllReadIconButton'),
                    onPressed: state.markingAllRead ? null : controller.markAllRead,
                    icon: const Icon(Icons.done_all, color: AppColors.textSecondary),
                    tooltip: 'Mark all read',
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Stay updated with important activities.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            Expanded(child: _Body(state: state, controller: controller)),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.state, required this.controller});

  final NotificationsState state;
  final NotificationsController controller;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      widget.controller.loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    switch (state.status) {
      case NotificationsLoadStatus.idle:
      case NotificationsLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case NotificationsLoadStatus.error:
        return _ErrorState(onRetry: widget.controller.refresh);
      case NotificationsLoadStatus.loaded:
        if (state.notifications.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none,
            title: 'No notifications yet.',
            message: "You're all caught up.",
          );
        }
        final hasAnyRead = state.notifications.any((n) => n.isRead);
        return RefreshIndicator(
          onRefresh: widget.controller.refresh,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              ..._groupedRows(state.notifications, widget.state, widget.controller),
              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('notificationsMarkAllReadButton'),
                      onPressed: state.markingAllRead ? null : widget.controller.markAllRead,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: Text(state.markingAllRead ? 'Marking...' : 'Mark All Read'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('notificationsClearReadButton'),
                      onPressed: (!hasAnyRead || state.clearingRead) ? null : widget.controller.clearRead,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(state.clearingRead ? 'Clearing...' : 'Clear Read'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  List<Widget> _groupedRows(
    List<AppNotification> notifications,
    NotificationsState state,
    NotificationsController controller,
  ) {
    final widgets = <Widget>[];
    String? lastLabel;

    for (final notification in notifications) {
      final label = _dayLabel(notification.createdAt);
      if (label != lastLabel) {
        if (lastLabel != null) widgets.add(const SizedBox(height: 8));
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
          ),
        );
        lastLabel = label;
      }
      widgets.add(
        _NotificationRow(
          notification: notification,
          pending: state.pendingMarkReadIds.contains(notification.id),
          onTap: notification.isRead ? null : () => controller.markRead(notification.id),
        ),
      );
    }

    return widgets;
  }
}

String _dayLabel(DateTime createdAt) {
  final local = createdAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final createdDay = DateTime(local.year, local.month, local.day);
  final difference = today.difference(createdDay).inDays;

  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';

  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${monthNames[local.month - 1]} ${local.day}, ${local.year}';
}

String _formatTime(DateTime createdAt) {
  final local = createdAt.toLocal();
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final hour12Raw = local.hour % 12;
  final hour12 = hour12Raw == 0 ? 12 : hour12Raw;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

/// One neutral bell-icon treatment for every notification — Notification
/// has no category column, so no per-category icon/color is derived.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.pending, required this.onTap});

  final AppNotification notification;
  final bool pending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;

    return InkWell(
      key: Key('notificationRow-${notification.id}'),
      onTap: pending ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.brandPrimary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_outlined, color: AppColors.brandPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                key: Key('unreadDot-${notification.id}'),
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.brandPrimary, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Could not load notifications.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
