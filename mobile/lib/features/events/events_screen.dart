import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/primary_button.dart';
import 'event_lifecycle_badge.dart';
import 'event_models.dart';
import 'events_list_controller.dart';

/// Matches design/ui-reference/9.png's Events List composition (header,
/// search, category filter, All/Upcoming/Today/Completed/Cancelled tabs,
/// event rows). Per Product Task 061's locked scope: rows show only real
/// title/date/time/venue plus a presentation-derived lifecycle badge — no
/// "Expected: N people" (no capacity authority), no category-keyed
/// icon/color (category has no fixed taxonomy). The frozen reference's
/// bottom "Add Person" button is a flagged reference anomaly (Events has no
/// functional relationship to Person creation); the truthful action here is
/// Create Event.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
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
      ref.read(eventsListControllerProvider.notifier).loadNextPage();
    }
  }

  Future<void> _openCategoryFilter(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Filter by category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter a category'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(''), child: const Text('Clear')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result != null) {
      ref.read(eventsListControllerProvider.notifier).updateCategory(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsListControllerProvider);
    final controller = ref.read(eventsListControllerProvider.notifier);
    final showFab = state.status == EventsLoadStatus.loaded;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/events/create'),
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
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
                child: _SearchAndFilterRow(
                  controller: _searchController,
                  onSearchChanged: controller.updateSearch,
                  onFilterTap: () => _openCategoryFilter(context, state.category),
                ),
              ),
              SliverToBoxAdapter(
                child: _LifecycleTabRow(selected: state.lifecycleFilter, onSelected: controller.updateLifecycleFilter),
              ),
              ..._contentSlivers(state, controller),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(EventsListState state, EventsListController controller) {
    switch (state.status) {
      case EventsLoadStatus.idle:
      case EventsLoadStatus.loading:
        return [
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator())),
        ];
      case EventsLoadStatus.error:
        return [
          SliverFillRemaining(hasScrollBody: false, child: _ErrorState(onRetry: controller.refresh)),
        ];
      case EventsLoadStatus.loaded:
        final visible = state.visibleEvents;
        if (visible.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.event_outlined,
                title: state.events.isEmpty ? 'No events yet.' : 'No events match this filter.',
                message: state.events.isEmpty
                    ? 'Create your first event to get started.'
                    : 'Try a different tab, search, or category.',
                action: state.events.isEmpty
                    ? PrimaryButton(
                        label: 'Create Event',
                        icon: Icons.add,
                        onPressed: () => context.push('/events/create'),
                      )
                    : null,
              ),
            ),
          ];
        }
        return [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _EventRow(event: visible[index]),
              childCount: visible.length,
            ),
          ),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
          Text('Events', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text(
            'Manage every event in your organization.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterRow extends StatelessWidget {
  const _SearchAndFilterRow({required this.controller, required this.onSearchChanged, required this.onFilterTap});

  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search events...',
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
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: IconButton(
              onPressed: onFilterTap,
              icon: const Icon(Icons.filter_list, color: AppColors.textSecondary),
              tooltip: 'Filter by category',
            ),
          ),
        ],
      ),
    );
  }
}

class _LifecycleTabRow extends StatelessWidget {
  const _LifecycleTabRow({required this.selected, required this.onSelected});

  final EventLifecycleFilter selected;
  final ValueChanged<EventLifecycleFilter> onSelected;

  static const _entries = [
    (EventLifecycleFilter.all, 'All'),
    (EventLifecycleFilter.upcoming, 'Upcoming'),
    (EventLifecycleFilter.today, 'Today'),
    (EventLifecycleFilter.completed, 'Completed'),
    (EventLifecycleFilter.cancelled, 'Cancelled'),
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

String _formatRowDateTime(DateTime startDate) {
  final local = startDate.toLocal();
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final hour12Raw = local.hour % 12;
  final hour12 = hour12Raw == 0 ? 12 : hour12Raw;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day}/${local.year} • $hour12:$minute $period';
}

/// Neutral icon/color regardless of category — category is free text with
/// no fixed taxonomy/color authority (Product Task 061 ruling).
class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final EventSummary event;

  @override
  Widget build(BuildContext context) {
    final status = deriveEventLifecycleStatus(event);
    final venue = event.venue;

    return InkWell(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSubtle))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(color: const Color(0xFF2563FF).withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.event_outlined, color: Color(0xFF2563FF), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      EventLifecycleBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRowDateTime(event.startDate),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (venue != null && venue.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(venue, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ],
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
              'Could not load events.',
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
