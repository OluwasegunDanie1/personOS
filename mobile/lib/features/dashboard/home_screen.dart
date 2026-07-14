import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../auth/auth_session_controller.dart';
import '../organizations/organization_context_controller.dart';
import 'dashboard_models.dart';
import 'dashboard_provider.dart';

/// Matches design/ui-reference/5.png's dashboard composition (greeting
/// header, 2x2 metric card grid, Quick Actions, upcoming events list, recent
/// members list, pending tasks list). The reference also shows a Today's
/// Attendance metric and a Recent Activity feed — neither has a supporting
/// field on the approved Dashboard Summary response (Product Task
/// 054/056), so neither is rendered or faked. Of the reference's four
/// Quick Actions (Add Person / Create Event / Record Attendance / Send
/// Announcement), only Add Person has an approved route (`/people/add`);
/// Create Event, Record Attendance, and Send Announcement have no approved
/// route/action yet (Events and Messages are both explicit "not yet
/// available" placeholders, and no attendance-recording screen exists), so
/// each is individually omitted rather than rendered as a fake/dead button
/// (Product Task 056A). Pending Tasks renders the existing FollowUp domain
/// only — no task priority, category, or completion-percentage is
/// fabricated. Recent Members/Pending Tasks omit the frozen reference's
/// "View all" links since no approved destination screen/route exists for
/// either yet.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final authState = ref.watch(authSessionControllerProvider);
    final organizationContext = ref.watch(organizationContextControllerProvider);

    final firstName = authState.user?.firstName;
    final organizationName = organizationContext is OrganizationContextActive
        ? organizationContext.selected.name
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
          child: summary.when(
            data: (data) => _DashboardBody(
              summary: data,
              greeting: _greeting(),
              firstName: firstName,
              organizationName: organizationName,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Could not load the dashboard. Pull down to retry.')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.summary,
    required this.greeting,
    required this.firstName,
    required this.organizationName,
  });

  final DashboardSummary summary;
  final String greeting;
  final String? firstName;
  final String? organizationName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '$greeting${firstName != null ? ', $firstName.' : '.'}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
            IconButton(
              key: const Key('homeNotificationsBellButton'),
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
              tooltip: 'Notifications',
            ),
          ],
        ),
        if (organizationName != null) ...[
          const SizedBox(height: 4),
          Text(organizationName!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.groups_outlined,
                iconColor: const Color(0xFF2563FF),
                value: '${summary.totalPeople}',
                label: 'Total People',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.person_add_alt_outlined,
                iconColor: const Color(0xFF16A34A),
                value: '${summary.newPeople}',
                label: 'New People',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.schedule_outlined,
                iconColor: const Color(0xFFD97706),
                value: '${summary.pendingFollowUps}',
                label: 'Pending Follow-ups',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.event_outlined,
                iconColor: const Color(0xFF7C3AED),
                value: '${summary.upcomingEvents.length}',
                label: 'Upcoming Events',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Quick actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: Icons.person_add_alt_outlined,
          label: 'Add Person',
          onTap: () => context.push('/people/add'),
        ),
        const SizedBox(height: 28),
        const Text(
          'Upcoming events',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (summary.upcomingEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No upcoming events.', style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ...summary.upcomingEvents.map((event) => _UpcomingEventTile(event: event)),
        const SizedBox(height: 28),
        const Text(
          'Recent members',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (summary.recentMembers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No recent members.', style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ...summary.recentMembers.map((member) => _RecentMemberTile(member: member)),
        const SizedBox(height: 28),
        const Text(
          'Pending tasks',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (summary.pendingTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No pending tasks.', style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ...summary.pendingTasks.map((task) => _PendingTaskTile(task: task)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.iconColor, required this.value, required this.label});

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('homeQuickActionTileInkWell'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFF2563FF).withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: const Color(0xFF2563FF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingEventTile extends StatelessWidget {
  const _UpcomingEventTile({required this.event});

  final UpcomingEvent event;

  @override
  Widget build(BuildContext context) {
    final local = event.startDate.toLocal();
    final formatted = '${local.month}/${local.day}/${local.year} • '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.event_outlined, color: Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(formatted, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatMonthDayYear(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

/// Derives "today"/"tomorrow" from the real dueDate compared against the
/// device's local calendar day — presentation-only, not an invented
/// urgency/priority classification (mirrors the existing Follow-Up due-date
/// display convention elsewhere in this codebase).
String _formatDueLabel(DateTime dueDate) {
  final local = dueDate.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(local.year, local.month, local.day);
  final difference = dueDay.difference(today).inDays;

  if (difference == 0) return 'Due today';
  if (difference == 1) return 'Due tomorrow';
  return 'Due ${_formatMonthDayYear(local)}';
}

class _RecentMemberTile extends StatelessWidget {
  const _RecentMemberTile({required this.member});

  final RecentMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF2563FF).withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Center(
              child: Text(
                member.initials,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563FF), fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(
                  'Joined ${_formatMonthDayYear(member.joinedAt.toLocal())}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingTaskTile extends StatelessWidget {
  const _PendingTaskTile({required this.task});

  final PendingTask task;

  @override
  Widget build(BuildContext context) {
    final description = task.description;
    final dueDate = task.dueDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.schedule_outlined, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (description != null && description.isNotEmpty)
                  Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (dueDate != null)
                  Text(
                    _formatDueLabel(dueDate),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
