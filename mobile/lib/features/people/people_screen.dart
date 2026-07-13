import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/empty_state.dart';
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

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
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
                child: _StatusFilterRow(
                  selected: state.statusFilter,
                  onSelected: controller.updateStatusFilter,
                ),
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
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.groups_outlined,
                title: 'No people yet.',
                message: 'Start building your community by adding your first person.',
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

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person});

  final PersonSummary person;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        person.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusDot(status: person.status),
                  ],
                ),
                if (person.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    person.email!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (person.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    person.phone!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final PersonStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == PersonStatus.active ? const Color(0xFF16A34A) : AppColors.textSecondary;
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.person});

  final PersonSummary person;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = person.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(radius: 26, backgroundImage: NetworkImage(avatarUrl));
    }

    final initials = person.initials;
    if (initials.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        child: Text(
          initials,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
        ),
      );
    }

    return CircleAvatar(
      radius: 26,
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
