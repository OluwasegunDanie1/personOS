import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../people/people_models.dart';
import 'event_check_in_controller.dart';
import 'events_provider.dart';

/// Focused Event Check-In screen (Product Task 069), reached from Event
/// Detail's "Check In" action. Renders only real, truthful authority:
/// the real Event (title/date, via eventDetailProvider), a real searched
/// list of active People in the current organization, and a single real
/// check-in action per person using the existing
/// POST .../events/:eventId/attendance endpoint (always the backend's own
/// default status — no status picker, since only one truthful check-in
/// action is implemented). Attendance is immutable: once a person is
/// checked in there is no undo/remove/edit/reverse control anywhere on
/// this screen. There is no QR scanning, bulk check-in, guest check-in,
/// RSVP/registration, or expected-attendee count — none of that authority
/// exists.
class EventCheckInScreen extends ConsumerStatefulWidget {
  const EventCheckInScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventCheckInScreen> createState() => _EventCheckInScreenState();
}

class _EventCheckInScreenState extends ConsumerState<EventCheckInScreen> {
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
      ref.read(eventCheckInControllerProvider(widget.eventId).notifier).loadNextPage();
    }
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/events/${widget.eventId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final attendanceAsync = ref.watch(eventAttendanceProvider(widget.eventId));
    final state = ref.watch(eventCheckInControllerProvider(widget.eventId));
    final controller = ref.read(eventCheckInControllerProvider(widget.eventId).notifier);

    // Real, previously-recorded check-ins (from before this session, or
    // from another device) merged with this session's own confirmed
    // check-ins — never fabricated, both sourced from real server data.
    final alreadyCheckedIn = <String>{
      ...state.checkedInPersonIds,
      ...attendanceAsync.when(
        data: (result) => result.attendance.map((a) => a.personId),
        loading: () => const <String>[],
        error: (error, stackTrace) => const <String>[],
      ),
    };

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
                  IconButton(
                    onPressed: () => _back(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  Expanded(
                    child: eventAsync.when(
                      data: (event) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Event Check-In',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (error, stackTrace) => const Text(
                        'Event Check-In',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: controller.updateSearch,
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
            ),
            if (state.checkInErrorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Could not check in that person. Please try again.',
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            Expanded(
              child: _PeopleList(
                state: state,
                controller: controller,
                scrollController: _scrollController,
                alreadyCheckedIn: alreadyCheckedIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeopleList extends StatelessWidget {
  const _PeopleList({
    required this.state,
    required this.controller,
    required this.scrollController,
    required this.alreadyCheckedIn,
  });

  final EventCheckInState state;
  final EventCheckInController controller;
  final ScrollController scrollController;
  final Set<String> alreadyCheckedIn;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case PeopleSearchStatus.idle:
      case PeopleSearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case PeopleSearchStatus.error:
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
                const SizedBox(height: 16),
                OutlinedButton(onPressed: controller.refresh, child: const Text('Retry')),
              ],
            ),
          ),
        );
      case PeopleSearchStatus.loaded:
        if (state.people.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'No people found.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: state.people.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.people.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final person = state.people[index];
            return _PersonCheckInRow(
              person: person,
              pending: state.pendingPersonIds.contains(person.id),
              checkedIn: alreadyCheckedIn.contains(person.id),
              onCheckIn: () => controller.checkIn(person.id),
            );
          },
        );
    }
  }
}

class _PersonCheckInRow extends StatelessWidget {
  const _PersonCheckInRow({
    required this.person,
    required this.pending,
    required this.checkedIn,
    required this.onCheckIn,
  });

  final PersonSummary person;
  final bool pending;
  final bool checkedIn;
  final VoidCallback onCheckIn;

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
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
            child: Text(
              person.initials,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandPrimary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              person.displayName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _CheckInAction(pending: pending, checkedIn: checkedIn, onCheckIn: onCheckIn, personId: person.id),
        ],
      ),
    );
  }
}

/// Attendance is immutable: a checked-in person only ever shows a
/// non-interactive confirmation — there is no undo/remove/edit/reverse
/// affordance anywhere in this row.
class _CheckInAction extends StatelessWidget {
  const _CheckInAction({
    required this.pending,
    required this.checkedIn,
    required this.onCheckIn,
    required this.personId,
  });

  final bool pending;
  final bool checkedIn;
  final VoidCallback onCheckIn;
  final String personId;

  @override
  Widget build(BuildContext context) {
    if (checkedIn) {
      return Container(
        key: Key('checkedInBadge-$personId'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 16),
            SizedBox(width: 4),
            Text('Checked In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
          ],
        ),
      );
    }

    if (pending) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return FilledButton(
      key: Key('checkInButton-$personId'),
      onPressed: onCheckIn,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      child: const Text('Check In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
