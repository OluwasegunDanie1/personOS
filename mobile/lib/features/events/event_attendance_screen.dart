import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/relvio_back_button.dart';
import 'event_models.dart';
import 'events_provider.dart';

/// Read-only Event Attendance list (Product Task 062), reached from Event
/// Detail's Attendance action. Renders only real, already-recorded
/// check-in Attendance records via GET .../events/:eventId/attendance — no
/// check-in mutation, no RSVP/registration wording, no guest invention.
/// A single bounded first page is shown (mirrors PersonProfileController's
/// Upcoming Follow-ups precedent): no fabricated total, an honest
/// "more exist" note instead of recursively following nextCursor.
class EventAttendanceScreen extends ConsumerWidget {
  const EventAttendanceScreen({super.key, required this.eventId});

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
    final attendanceAsync = ref.watch(eventAttendanceProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  RelvioBackButton(onPressed: () => _back(context)),
                  const SizedBox(width: 4),
                  const Text(
                    'Attendance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: attendanceAsync.when(
                data: (result) => _AttendanceBody(eventId: eventId, result: result),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _ErrorState(
                  onRetry: () => ref.refresh(eventAttendanceProvider(eventId).future),
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
              'Could not load attendance.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  const _AttendanceBody({required this.eventId, required this.result});

  final String eventId;
  final EventAttendanceListResult result;

  @override
  Widget build(BuildContext context) {
    if (result.attendance.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'No attendance has been recorded for this event yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: result.attendance.length + (result.nextCursor != null ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= result.attendance.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'More attendance records exist for this event.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          );
        }
        return _AttendanceRow(record: result.attendance[index]);
      },
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.record});

  final EventAttendanceRecord record;

  String get _initials {
    final first = record.personFirstName.trim().isNotEmpty ? record.personFirstName.trim()[0] : '';
    final last = record.personLastName.trim().isNotEmpty ? record.personLastName.trim()[0] : '';
    return ('$first$last').toUpperCase();
  }

  String _formatCheckedInAt(DateTime checkedInAt) {
    final local = checkedInAt.toLocal();
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final hour12Raw = local.hour % 12;
    final hour12 = hour12Raw == 0 ? 12 : hour12Raw;
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day}/${local.year} • $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
            child: Text(
              _initials,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandPrimary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.personDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCheckedInAt(record.checkedInAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _StatusChip(status: record.status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  Color get _color {
    switch (status) {
      case 'PRESENT':
        return const Color(0xFF16A34A);
      case 'LATE':
        return const Color(0xFFD97706);
      case 'ABSENT':
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
