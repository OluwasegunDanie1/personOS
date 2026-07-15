import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/date_time_picker_fields.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/relvio_back_button.dart';
import 'edit_event_controller.dart';
import 'event_models.dart';

/// Matches design/ui-reference/9.png's "Edit Event" composition, narrowed to
/// Product Task 062's locked scope: Event Name, Category, Description,
/// Schedule (Date/Start Time/End Time), Venue are editable; Save Changes
/// (real PATCH + real post-save refresh) and Cancel Event (real POST
/// .../cancel, confirmation-gated, one-way — no uncancel UI) are both real
/// actions. Cover upload, Attendance settings, and Notifications settings
/// are omitted (no backend authority). Initial values come exclusively from
/// this screen's own independent GET Detail load — never List summary data
/// or route-passed state.
class EditEventScreen extends ConsumerStatefulWidget {
  const EditEventScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _showScheduleError = false;

  /// True once the form controls have been populated from the real, loaded
  /// Event Detail. Guards against a later state change (e.g. retryLoad)
  /// ever clobbering values the user has already started editing.
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [_titleController, _categoryController, _descriptionController, _venueController]) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _hydrate(EventDetail detail) {
    _titleController.text = detail.title;
    _categoryController.text = detail.category ?? '';
    _descriptionController.text = detail.description ?? '';
    _venueController.text = detail.venue ?? '';
    final localStart = detail.startDate.toLocal();
    _date = DateTime(localStart.year, localStart.month, localStart.day);
    _startTime = TimeOfDay(hour: localStart.hour, minute: localStart.minute);
    final localEnd = detail.endDate?.toLocal();
    _endTime = localEnd != null ? TimeOfDay(hour: localEnd.hour, minute: localEnd.minute) : null;
    _hydrated = true;
  }

  void _cancel() {
    ref.read(editEventControllerProvider(widget.eventId).notifier).closeSession();
    if (context.canPop()) context.pop();
  }

  void _setDate(DateTime? value) => setState(() => _date = value);

  void _setStartTime(TimeOfDay? value) => setState(() => _startTime = value);

  void _setEndTime(TimeOfDay? value) => setState(() => _endTime = value);

  EditEventFormValues _currentFormValues() {
    final date = _date;
    final startTime = _startTime;
    final startDate = (date != null && startTime != null)
        ? DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute)
        : null;
    final endTime = _endTime;
    final endDate = (date != null && endTime != null)
        ? DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute)
        : null;

    return EditEventFormValues(
      title: _titleController.text,
      category: _categoryController.text,
      description: _descriptionController.text,
      venue: _venueController.text,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    final scheduleValid = _date != null && _startTime != null;
    setState(() => _showScheduleError = !scheduleValid);

    if (!formValid || !scheduleValid) return;

    await ref.read(editEventControllerProvider(widget.eventId).notifier).submit(_currentFormValues());
  }

  Future<void> _confirmCancelEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this event?'),
        content: const Text(
          'This marks the event as cancelled. It remains visible in Events, but this action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Keep Event')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Event'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(editEventControllerProvider(widget.eventId).notifier).cancelEvent();
    }
  }

  String? _titleValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Event name is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editEventControllerProvider(widget.eventId));

    ref.listen(editEventControllerProvider(widget.eventId), (previous, next) {
      if (next.loadStatus == EditEventLoadStatus.loaded && !_hydrated && next.detail != null) {
        setState(() => _hydrate(next.detail!));
      }

      final shouldPop =
          next.submitStatus == EditEventSubmitStatus.success ||
          next.cancelStatus == EditEventCancelStatus.success ||
          next.shouldClose;
      if (shouldPop && context.canPop()) {
        context.pop();
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        ref.read(editEventControllerProvider(widget.eventId).notifier).closeSession();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    RelvioBackButton(onPressed: _cancel),
                    const Spacer(),
                    if (state.loadStatus == EditEventLoadStatus.loaded &&
                        _hydrated &&
                        ref.read(editEventControllerProvider(widget.eventId).notifier).isDirty(_currentFormValues()))
                      const _UnsavedChangesBadge(),
                  ],
                ),
              ),
              Expanded(child: _Body(eventId: widget.eventId, state: state, screenState: this)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnsavedChangesBadge extends StatelessWidget {
  const _UnsavedChangesBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Unsaved changes',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.eventId, required this.state, required this.screenState});

  final String eventId;
  final EditEventState state;
  final _EditEventScreenState screenState;

  @override
  Widget build(BuildContext context) {
    switch (state.loadStatus) {
      case EditEventLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case EditEventLoadStatus.error:
        return _LoadErrorState(
          onRetry: () => screenState.ref.read(editEventControllerProvider(eventId).notifier).retryLoad(),
        );
      case EditEventLoadStatus.loaded:
        return _EditForm(eventId: eventId, state: state, screenState: screenState);
    }
  }
}

class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({required this.onRetry});

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

class _EditForm extends StatelessWidget {
  const _EditForm({required this.eventId, required this.state, required this.screenState});

  final String eventId;
  final EditEventState state;
  final _EditEventScreenState screenState;

  @override
  Widget build(BuildContext context) {
    final submitting = state.submitStatus == EditEventSubmitStatus.submitting;
    final cancelling = state.cancelStatus == EditEventCancelStatus.cancelling;
    final detail = state.detail!;
    final isCancelled = detail.cancelledAt != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: screenState._formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Event',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Update event information before it begins.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            LabeledTextField(
              label: 'Event Name',
              hintText: 'Enter event name',
              controller: screenState._titleController,
              validator: screenState._titleValidator,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Category',
              hintText: 'e.g. Worship, Meeting, Outreach',
              controller: screenState._categoryController,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Description',
              hintText: 'Add a description about your event...',
              controller: screenState._descriptionController,
            ),
            const SizedBox(height: 20),
            DateField(
              key: const Key('editEventDateField'),
              label: 'Date',
              value: screenState._date,
              onChanged: screenState._setDate,
            ),
            const SizedBox(height: 20),
            TimeField(
              key: const Key('editEventStartTimeField'),
              label: 'Start Time',
              value: screenState._startTime,
              onChanged: screenState._setStartTime,
            ),
            const SizedBox(height: 20),
            TimeField(
              key: const Key('editEventEndTimeField'),
              label: 'End Time',
              value: screenState._endTime,
              onChanged: screenState._setEndTime,
              hintText: 'Select time (optional)',
              optional: true,
            ),
            if (screenState._showScheduleError) ...[
              const SizedBox(height: 8),
              const Text('Date and Start Time are required.', style: TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Venue',
              hintText: 'Enter location',
              controller: screenState._venueController,
              icon: Icons.location_on_outlined,
            ),
            if (state.submitStatus == EditEventSubmitStatus.error) ...[
              const SizedBox(height: 12),
              Text(
                state.submitErrorMessage ?? 'Could not save these changes. Please try again.',
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            if (state.submitStatus == EditEventSubmitStatus.noChange) ...[
              const SizedBox(height: 12),
              const Text('No changes to save.', style: TextStyle(color: AppColors.textSecondary)),
            ],
            if (state.cancelStatus == EditEventCancelStatus.error) ...[
              const SizedBox(height: 12),
              Text(
                state.cancelErrorMessage ?? 'Could not cancel this event. Please try again.',
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Save Changes',
              onPressed: submitting ? null : () => screenState._submit(),
              loading: submitting,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: isCancelled || cancelling ? null : () => screenState._confirmCancelEvent(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isCancelled ? 'Event Already Cancelled' : (cancelling ? 'Cancelling...' : 'Cancel Event'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
