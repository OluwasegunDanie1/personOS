import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import 'people_models.dart';
import 'person_profile_controller.dart';

/// Matches design/ui-reference/7.png panel 2's Person Profile composition
/// (Product Task 038 controller ruling: 7.png is the controlling Journey
/// Stage-stepper treatment, not 6.png's narrative timeline). Renders only
/// the four real approved API dependencies (Person Detail, Person Journey,
/// Journey Stages, Attendance Summary); Groups/Recent Activity/Upcoming
/// Follow-ups are omitted (no backend authority), Notes is a non-interactive
/// structural row (no backend authority), and Call/Message/Email/More/
/// Create Follow-up/Edit Person are non-interactive (no approved product
/// behavior in this first slice).
class PersonProfileScreen extends ConsumerWidget {
  const PersonProfileScreen({super.key, required this.personId});

  final String personId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/people');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personProfileControllerProvider(personId));

    ref.listen(personProfileControllerProvider(personId), (previous, next) {
      if (next.shouldClose) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/people');
        }
      }
    });

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
            Expanded(child: _ProfileBody(personId: personId, state: state)),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.personId, required this.state});

  final String personId;
  final PersonProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.status) {
      case ProfileLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ProfileLoadStatus.error:
        return _ProfileErrorState(
          onRetry: () => ref.read(personProfileControllerProvider(personId).notifier).retry(),
        );
      case ProfileLoadStatus.loaded:
        final detail = state.detail!;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(detail: detail),
              const SizedBox(height: 20),
              const _ActionRow(),
              const SizedBox(height: 20),
              _PersonalInformationSection(detail: detail),
              const SizedBox(height: 12),
              _AttendanceSummarySection(summary: state.attendanceSummary),
              const SizedBox(height: 12),
              _JourneyStageSection(journey: state.journey, stages: state.stages ?? const []),
              const SizedBox(height: 12),
              const _NotesStructuralRow(),
              const SizedBox(height: 12),
              _UpcomingFollowUpsSection(
                personId: personId,
                status: state.followUpStatus,
                followUps: state.followUps,
                hasMore: state.followUpsHasMore,
              ),
              const SizedBox(height: 24),
              _BottomActions(personId: personId),
            ],
          ),
        );
    }
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.onRetry});

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
              'Could not load this person.',
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

/// Header: back affordance lives in the parent Scaffold; this covers avatar,
/// name, and the two status/journey pills. No green presence dot — no
/// online/offline authority exists anywhere in the backend.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.detail});

  final PersonDetail detail;

  @override
  Widget build(BuildContext context) {
    final stage = detail.currentJourneyStage;

    return Center(
      child: Column(
        children: [
          _ProfileAvatar(detail: detail),
          const SizedBox(height: 12),
          Text(
            detail.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(status: detail.status),
              if (stage != null) _JourneyPill(name: stage.name),
            ],
          ),
        ],
      ),
    );
  }
}

/// Truthful ACTIVE/INACTIVE presentation only — never relabelled as Member/
/// Active Member/Visitor/Volunteer/Leader (no such backend authority exists;
/// Person.status is a closed two-value allowlist).
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final PersonStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == PersonStatus.active;
    final color = isActive ? const Color(0xFF16A34A) : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Uses the real currentJourneyStage.name only — never a hardcoded/
/// illustrative stage label.
class _JourneyPill extends StatelessWidget {
  const _JourneyPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.25)),
      ),
      child: Text(
        'Journey: $name',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandPrimary),
      ),
    );
  }
}

/// Same avatarUrl read/fallback precedent as People's _PersonAvatar (Product
/// Task 036): loading and broken-URL states both fall back to the same
/// stable initials/icon treatment, never Flutter's default broken-image
/// glyph. No upload/edit-photo affordance — that remains deferred.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.detail});

  final PersonDetail detail;

  static const double _diameter = 96;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = detail.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: _diameter,
          height: _diameter,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : _fallback(),
          errorBuilder: (context, error, stackTrace) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    final initials = detail.initials;
    if (initials.isNotEmpty) {
      return CircleAvatar(
        radius: _diameter / 2,
        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        child: Text(
          initials,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
        ),
      );
    }

    return CircleAvatar(
      radius: _diameter / 2,
      backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
      child: const Icon(Icons.person_outline, size: 40, color: AppColors.brandPrimary),
    );
  }
}

/// Call/Message/Email/More: preserved composition, all four non-interactive
/// in this first slice (no url_launcher/tel:/sms:/mailto:, no in-app
/// messaging, no menu-item authority). Muted (grey, not brand-blue) so the
/// treatment does not visually suggest an available action.
class _ActionRow extends StatelessWidget {
  const _ActionRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _ActionItem(icon: Icons.call_outlined, label: 'Call'),
        _ActionItem(icon: Icons.chat_bubble_outline, label: 'Message'),
        _ActionItem(icon: Icons.mail_outline, label: 'Email'),
        _ActionItem(icon: Icons.more_horiz, label: 'More'),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.borderSubtle,
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, this.subtitle, this.child});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? child;

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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
          ],
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}

/// Renders only real, non-null Person Detail fields. Null fields are
/// omitted entirely — never a fabricated placeholder value.
class _PersonalInformationSection extends StatelessWidget {
  const _PersonalInformationSection({required this.detail});

  final PersonDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    void addRow(String label, String value) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(_InfoRow(label: label, value: value));
    }

    if (detail.phone != null && detail.phone!.isNotEmpty) addRow('Phone', detail.phone!);
    if (detail.email != null && detail.email!.isNotEmpty) addRow('Email', detail.email!);
    if (detail.gender != null) addRow('Gender', detail.gender!.displayLabel);
    if (detail.dateOfBirth != null) addRow('Date of Birth', _formatDateOnly(detail.dateOfBirth!));
    if (detail.address != null && detail.address!.isNotEmpty) addRow('Address', detail.address!);

    return _SectionCard(
      icon: Icons.person_outline,
      title: 'Personal Information',
      child: rows.isEmpty
          ? const Text('No additional details on file.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Reads .year/.month/.day directly off the UTC-midnight DateTime produced
/// by parseDateOnly — never .toLocal(), so the calendar date exactly matches
/// what the backend persisted regardless of device timezone.
String _formatDateOnly(DateTime dateOnly) => '${_monthNames[dateOnly.month - 1]} ${dateOnly.day}, ${dateOnly.year}';

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Real totalCount/currentMonthCount only — never latestAttendance, a
/// percentage, a streak, or a trend.
class _AttendanceSummarySection extends StatelessWidget {
  const _AttendanceSummarySection({required this.summary});

  final AttendanceSummary? summary;

  @override
  Widget build(BuildContext context) {
    final total = summary?.totalCount ?? 0;
    final month = summary?.currentMonthCount ?? 0;

    return _SectionCard(
      icon: Icons.bar_chart_outlined,
      title: 'Attendance Summary',
      subtitle: 'Total $total times  •  This month: $month times',
    );
  }
}

/// Journey Stage stepper (design/ui-reference/7.png panel 2's controlling
/// treatment, per Task 038's ruling). Real ordered stages from
/// GET /journey-stages; real current-stage position from
/// GET /people/:id/journey. A stage is "reached" (completed or current) iff
/// stage.position <= currentStage.position — this is an exact derivation
/// from the Journey endpoint's own position field, not an inference from
/// history/mockup data (see the completion report's documented rationale).
/// Per-stage dates use the most recent history entry whose toStage.id
/// matches that stage (movedAt-latest-wins, the same tie-break convention
/// already used throughout the backend for "current" journey resolution) —
/// stages never reached show no date. No stage names are hardcoded.
class _JourneyStageSection extends StatelessWidget {
  const _JourneyStageSection({required this.journey, required this.stages});

  final PersonJourneyView? journey;
  final List<JourneyStageListEntry> stages;

  @override
  Widget build(BuildContext context) {
    final currentPosition = journey?.currentStage?.position;

    final latestMovedAtByStageId = <String, DateTime>{};
    for (final entry in journey?.history ?? const <PersonJourneyHistoryEntry>[]) {
      final existing = latestMovedAtByStageId[entry.toStageId];
      if (existing == null || entry.movedAt.isAfter(existing)) {
        latestMovedAtByStageId[entry.toStageId] = entry.movedAt;
      }
    }

    return _SectionCard(
      icon: Icons.moving_outlined,
      title: 'Journey Stage',
      child: stages.isEmpty
          ? const Text(
              'No journey stages configured yet.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _JourneyStepRow(
                    stage: stages[i],
                    reached: currentPosition != null && stages[i].position <= currentPosition,
                    isCurrent: currentPosition != null && stages[i].position == currentPosition,
                    movedAt: latestMovedAtByStageId[stages[i].id],
                  ),
                ],
              ],
            ),
    );
  }
}

class _JourneyStepRow extends StatelessWidget {
  const _JourneyStepRow({
    required this.stage,
    required this.reached,
    required this.isCurrent,
    required this.movedAt,
  });

  final JourneyStageListEntry stage;
  final bool reached;
  final bool isCurrent;
  final DateTime? movedAt;

  @override
  Widget build(BuildContext context) {
    final color = reached ? const Color(0xFF2563FF) : AppColors.textSecondary.withValues(alpha: 0.4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          reached ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: reached ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              if (movedAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatDateOnly(DateTime.utc(movedAt!.year, movedAt!.month, movedAt!.day)),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Structural, non-interactive: no chevron (no available navigation), no
/// fabricated count, no Notes fetch. Notes has a Prisma model but no
/// backend/API domain (Task 038 §13/Task 041 ruling J).
class _NotesStructuralRow extends StatelessWidget {
  const _NotesStructuralRow();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(icon: Icons.notes_outlined, title: 'Notes');
  }
}

/// Create Follow-up is now interactive (Product Task 043), pushing
/// /people/:personId/follow-ups/create. Edit Person remains visually present
/// but disabled (onPressed: null renders Flutter's standard disabled button
/// treatment), per Task 041 ruling M — not implemented in this task.
class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () => context.push('/people/$personId/follow-ups/create'),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Create Follow-up', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Edit Person', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

/// "Upcoming Follow-ups" region (design/ui-reference/7.png panel 2's frozen
/// section identity). Renders only real, non-completed (PENDING/IN_PROGRESS)
/// Follow-up records from one bounded person-scoped page — never a fake
/// count, never an exhaustive-total claim when hasMore is true, never an
/// invented UPCOMING status. Rows are non-interactive: no chevron, no
/// navigation to a non-existent detail screen, no completion control.
class _UpcomingFollowUpsSection extends ConsumerWidget {
  const _UpcomingFollowUpsSection({
    required this.personId,
    required this.status,
    required this.followUps,
    required this.hasMore,
  });

  final String personId;
  final FollowUpRegionStatus status;
  final List<FollowUpSummary>? followUps;
  final bool hasMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (status) {
      case FollowUpRegionStatus.loading:
        return const _SectionCard(
          icon: Icons.schedule_outlined,
          title: 'Upcoming Follow-ups',
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
        );
      case FollowUpRegionStatus.error:
        return _SectionCard(
          icon: Icons.schedule_outlined,
          title: 'Upcoming Follow-ups',
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Could not load follow-ups.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => ref.read(personProfileControllerProvider(personId).notifier).refreshFollowUps(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      case FollowUpRegionStatus.loaded:
        final visible = followUps ?? const <FollowUpSummary>[];
        if (visible.isEmpty) {
          return const _SectionCard(
            icon: Icons.schedule_outlined,
            title: 'Upcoming Follow-ups',
            child: Text(
              'No follow-ups are currently scheduled.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }
        return _SectionCard(
          icon: Icons.schedule_outlined,
          title: 'Upcoming Follow-ups',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                _FollowUpRow(followUp: visible[i]),
              ],
              // hasMore never produces a total-count claim — the bounded
              // first page's records are simply shown as-is, with an honest
              // "more exist" note instead of a fabricated "{N} total".
              if (hasMore) ...[
                const SizedBox(height: 8),
                const Text(
                  'More follow-ups exist for this person.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        );
    }
  }
}

class _FollowUpRow extends StatelessWidget {
  const _FollowUpRow({required this.followUp});

  final FollowUpSummary followUp;

  @override
  Widget build(BuildContext context) {
    final dueDate = followUp.dueDate;
    final assignee = followUp.assignedTo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          followUp.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        if (dueDate != null) ...[
          const SizedBox(height: 2),
          Text(
            'Due ${_formatDateOnly(dueDate.toLocal())}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
        if (assignee != null) ...[
          const SizedBox(height: 2),
          Text(
            'Assigned to ${assignee.displayName}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
