import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/primary_button.dart';
import 'people_models.dart';
import 'people_state_controller.dart';

/// Matches design/ui-reference/6.png and 7.png's People Directory
/// composition (header, persistent search, status filter row, plain row
/// list, empty state). Per Task 031's controller rulings: the legacy
/// Visitor/Member/Volunteer/Leader taxonomy, "Last attendance", team/group
/// names, and journey-stage badges are not rendered — none of that data is
/// part of the approved PersonSummary contract. Add Person and Person
/// Profile are explicitly out of scope for this slice.
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  final _searchController = TextEditingController();
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
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(peopleDirectoryControllerProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(peopleDirectoryControllerProvider);
    final controller = ref.read(peopleDirectoryControllerProvider.notifier);
    final showFab = state.status == PeopleLoadStatus.loaded && state.people.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      // Floating (bottom-right, anchored above bottom nav), not full-width —
      // an extended FAB with icon + label rather than the screen-wide button.
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/people/add'),
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add Person'),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: _Header()),
              SliverToBoxAdapter(
                child: _SearchField(controller: _searchController, onChanged: controller.updateSearch),
              ),
              SliverToBoxAdapter(
                child: _StatusFilterRow(selected: state.statusFilter, onSelected: controller.updateStatusFilter),
              ),
              ..._contentSlivers(state, controller),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(PeopleDirectoryState state, PeopleDirectoryController controller) {
    switch (state.status) {
      case PeopleLoadStatus.idle:
      case PeopleLoadStatus.loading:
        return [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case PeopleLoadStatus.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorState(onRetry: controller.refresh),
          ),
        ];
      case PeopleLoadStatus.loaded:
        if (state.people.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.groups_outlined,
                title: 'No people yet.',
                message: 'Start building your community by adding your first person.',
                action: PrimaryButton(
                  label: 'Add First Person',
                  icon: Icons.person_add_outlined,
                  onPressed: () => context.push('/people/add'),
                ),
              ),
            ),
          ];
        }
        return [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PersonRow(person: state.people[index]),
              childCount: state.people.length,
            ),
          ),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ];
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('People', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text(
            'Manage everyone in your organization.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search people...',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          filled: true,
          fillColor: AppColors.surfaceCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({required this.selected, required this.onSelected});

  final PeopleStatusFilter selected;
  final ValueChanged<PeopleStatusFilter> onSelected;

  static const _entries = [
    (PeopleStatusFilter.all, 'All'),
    (PeopleStatusFilter.active, 'Active'),
    (PeopleStatusFilter.inactive, 'Inactive'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _entries.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label) = _entries[index];
          final isSelected = filter == selected;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(filter),
            showCheckmark: false,
            backgroundColor: AppColors.surfaceCard,
            selectedColor: AppColors.brandPrimary,
            side: BorderSide(color: isSelected ? AppColors.brandPrimary : AppColors.borderSubtle),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }
}

/// Tapping the row navigates to Person Profile (Product Task 041 §A: the
/// entry gesture itself, not a new visible affordance — no chevron/icon/
/// menu item is added, so the visible card composition is unchanged).
class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person});

  final PersonSummary person;

  @override
  Widget build(BuildContext context) {
    final phone = person.phone;
    final email = person.email;
    final stage = person.currentJourneyStage;
    final lastAttendance = person.lastAttendance;

    return InkWell(
      onTap: () => context.push('/people/${person.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSubtle))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PersonAvatar(person: person),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        person.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stage != null) _JourneyStageBadge(stage: stage),
                    ],
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _ContactRow(icon: Icons.phone_outlined, text: phone),
                  ],
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _ContactRow(icon: Icons.mail_outline, text: email),
                  ],
                ],
              ),
            ),
            if (lastAttendance != null) ...[
              const SizedBox(width: 12),
              _LastAttendanceBlock(checkedInAt: lastAttendance.checkedInAt),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// One neutral, consistent pill treatment for every journey stage — Journey
/// Stage carries no authoritative color field, and stage names are fully
/// organization-configurable, so no color/semantic meaning is derived from
/// the name itself (see Product Task 034/035 authority).
class _JourneyStageBadge extends StatelessWidget {
  const _JourneyStageBadge({required this.stage});

  final JourneyStageSummary stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.25)),
      ),
      child: Text(
        stage.name,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

const _lastAttendanceMonthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Today, h:mm AM/PM for the device's local calendar-today; otherwise
/// MMM d, yyyy. Never shows seconds, timezone abbreviations, or raw ISO.
String formatLastAttendance(DateTime checkedInAt, {DateTime? now}) {
  final local = checkedInAt.toLocal();
  final reference = now ?? DateTime.now();

  final isToday = local.year == reference.year && local.month == reference.month && local.day == reference.day;

  if (isToday) {
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final hour12Raw = local.hour % 12;
    final hour12 = hour12Raw == 0 ? 12 : hour12Raw;
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Today, $hour12:$minute $period';
  }

  return '${_lastAttendanceMonthAbbreviations[local.month - 1]} ${local.day}, ${local.year}';
}

class _LastAttendanceBlock extends StatelessWidget {
  const _LastAttendanceBlock({required this.checkedInAt});

  final DateTime checkedInAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Last attendance', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          formatLastAttendance(checkedInAt),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.person});

  final PersonSummary person;

  static const double _diameter = 52;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = person.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: _diameter,
          height: _diameter,
          fit: BoxFit.cover,
          // Shows the same stable initials/icon fallback while loading and
          // on error — never Flutter's default broken-image glyph.
          loadingBuilder: (context, child, loadingProgress) =>
              loadingProgress == null ? child : _fallback(),
          errorBuilder: (context, error, stackTrace) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    final initials = person.initials;
    if (initials.isNotEmpty) {
      return CircleAvatar(
        radius: _diameter / 2,
        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        child: Text(
          initials,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
        ),
      );
    }

    return CircleAvatar(
      radius: _diameter / 2,
      backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
      child: const Icon(Icons.person_outline, color: AppColors.brandPrimary),
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
              'Could not load people.',
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
