import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import 'event_lifecycle_badge.dart';
import 'event_models.dart';
import 'events_provider.dart';

/// Matches design/ui-reference/9.png's Event Detail composition, narrowed to
/// Product Task 061's locked truthful scope: title, local date/time, venue,
/// description, createdBy, a presentation-derived lifecycle badge, Edit,
/// and an Attendance action that opens the real read-only Attendance list.
/// Omitted (no backend authority): cover image, the Expected/Checked-
/// in/Pending/Guest stat grid, Attendance Summary ring, Registered People,
/// Announcements, Notes, Recent Activity, Start Check-In. Share is also
/// omitted — device-native share would require adding a new dependency
/// (e.g. share_plus), which is not an existing convention in this codebase
/// and is out of this task's narrow scope (see completion report).
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/events');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: IconButton(
                onPressed: () => _back(context),
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
            ),
            Expanded(
              child: detailAsync.when(
                data: (detail) => _DetailBody(eventId: eventId, detail: detail),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _ErrorState(
                  onRetry: () => ref.refresh(eventDetailProvider(eventId).future),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

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
              'Could not load this event.',
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

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.eventId, required this.detail});

  final String eventId;
  final EventDetail detail;

  @override
  Widget build(BuildContext context) {
    final status = deriveEventLifecycleStatus(detail);
    final venue = detail.venue;
    final description = detail.description;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  detail.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              EventLifecycleBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.calendar_today_outlined, text: _formatDate(detail.startDate)),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.schedule_outlined, text: _formatTimeRange(detail.startDate, detail.endDate)),
          if (venue != null && venue.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.location_on_outlined, text: venue),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionItem(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => context.push('/events/$eventId/edit'),
              ),
              _ActionItem(
                icon: Icons.people_alt_outlined,
                label: 'Attendance',
                onTap: () => context.push('/events/$eventId/attendance'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (description != null && description.isNotEmpty) ...[
            _SectionCard(
              icon: Icons.description_outlined,
              title: 'Overview',
              child: Text(description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 12),
          ],
          _SectionCard(
            icon: Icons.person_outline,
            title: 'Created By',
            child: Text(
              detail.createdBy.displayName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => context.push('/events/$eventId/edit'),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Edit Event', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${_monthNames[local.month - 1]} ${local.day}, ${local.year}';
}

String _formatClock(DateTime date) {
  final local = date.toLocal();
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final hour12Raw = local.hour % 12;
  final hour12 = hour12Raw == 0 ? 12 : hour12Raw;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

String _formatTimeRange(DateTime startDate, DateTime? endDate) {
  if (endDate == null) return _formatClock(startDate);
  return '${_formatClock(startDate)} – ${_formatClock(endDate)}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
            child: Icon(icon, color: AppColors.brandPrimary, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brandPrimary),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
