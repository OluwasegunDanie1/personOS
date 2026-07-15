import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/date_time_picker_fields.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/relvio_back_button.dart';
import 'create_event_controller.dart';

/// Matches design/ui-reference/9.png's numbered-card "Create a new event."
/// composition (Event Information / Schedule / Venue), per Product Task
/// 062's locked scope. Renders only fields real Create Event authority
/// accepts: Event Name, Category (free text — no fixed taxonomy),
/// Description, Date (required), Start Time (required), End Time
/// (optional), Venue. Event Template quick-select, Event Cover upload, and
/// the Time Zone selector are omitted — no backend authority for any of
/// them (Product Task 058/061 rulings).
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _showScheduleError = false;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _cancel() {
    ref.read(createEventControllerProvider.notifier).cancel();
    if (context.canPop()) context.pop();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    final scheduleValid = _date != null && _startTime != null;
    setState(() => _showScheduleError = !scheduleValid);

    if (!formValid || !scheduleValid) return;

    final startDate = DateTime(_date!.year, _date!.month, _date!.day, _startTime!.hour, _startTime!.minute);
    final endTime = _endTime;
    final endDate = endTime != null
        ? DateTime(_date!.year, _date!.month, _date!.day, endTime.hour, endTime.minute)
        : null;

    await ref
        .read(createEventControllerProvider.notifier)
        .submit(
          title: _titleController.text,
          category: _categoryController.text,
          description: _descriptionController.text,
          venue: _venueController.text,
          startDate: startDate,
          endDate: endDate,
        );
  }

  String? _titleValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Event name is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventControllerProvider);

    ref.listen(createEventControllerProvider, (previous, next) {
      final shouldPop = next.status == CreateEventSubmitStatus.success || next.shouldClose;
      if (shouldPop && context.canPop()) {
        context.pop();
      }
    });

    final submitting = state.status == CreateEventSubmitStatus.submitting;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        ref.read(createEventControllerProvider.notifier).cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RelvioBackButton(onPressed: _cancel),
                  const SizedBox(height: 12),
                  const Text(
                    'Create a new event.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Plan an event and keep everyone informed.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    number: 1,
                    title: 'Event Information',
                    subtitle: 'Basic details about your event.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledTextField(
                          label: 'Event Name',
                          hintText: 'Enter event name',
                          controller: _titleController,
                          validator: _titleValidator,
                        ),
                        const SizedBox(height: 16),
                        LabeledTextField(
                          label: 'Category',
                          hintText: 'e.g. Worship, Meeting, Outreach',
                          controller: _categoryController,
                        ),
                        const SizedBox(height: 16),
                        LabeledTextField(
                          label: 'Description',
                          hintText: 'Add a description about your event...',
                          controller: _descriptionController,
                        ),
                      ],
                    ),
                  ),
                  _SectionCard(
                    number: 2,
                    title: 'Schedule',
                    subtitle: 'Choose the date and time.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DateField(
                          key: const Key('createEventDateField'),
                          label: 'Date',
                          value: _date,
                          onChanged: (value) => setState(() => _date = value),
                        ),
                        const SizedBox(height: 16),
                        TimeField(
                          key: const Key('createEventStartTimeField'),
                          label: 'Start Time',
                          value: _startTime,
                          onChanged: (value) => setState(() => _startTime = value),
                        ),
                        const SizedBox(height: 16),
                        TimeField(
                          key: const Key('createEventEndTimeField'),
                          label: 'End Time',
                          value: _endTime,
                          onChanged: (value) => setState(() => _endTime = value),
                          hintText: 'Select time (optional)',
                          optional: true,
                        ),
                        if (_showScheduleError) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Date and Start Time are required.',
                            style: TextStyle(color: AppColors.danger, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _SectionCard(
                    number: 3,
                    title: 'Venue',
                    subtitle: 'Where is your event happening?',
                    child: LabeledTextField(
                      label: 'Venue',
                      hintText: 'Enter location',
                      controller: _venueController,
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  if (state.status == CreateEventSubmitStatus.error) ...[
                    const SizedBox(height: 4),
                    Text(
                      state.errorMessage ?? 'Could not create this event. Please try again.',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Create Event', onPressed: submitting ? null : _submit, loading: submitting),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.number, required this.title, required this.subtitle, required this.child});

  final int number;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberBadge(number: number),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.brandPrimary, shape: BoxShape.circle),
      child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
