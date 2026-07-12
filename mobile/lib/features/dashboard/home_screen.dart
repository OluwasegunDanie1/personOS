import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../auth/auth_session_controller.dart';
import '../organizations/organization_context_controller.dart';
import 'dashboard_models.dart';
import 'dashboard_provider.dart';

/// Matches design/ui-reference/5.png's dashboard composition (greeting
/// header, 2x2 metric card grid, upcoming events list). The reference also
/// shows a Quick Actions grid and a Recent Activity feed — both require
/// data/actions (add person, create event, record attendance, send
/// announcement, activity log) that are explicitly out of Task 029's scope
/// and not present on the approved Dashboard Summary response, so neither
/// is rendered.
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
        Text(
          '$greeting${firstName != null ? ', $firstName.' : '.'}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
