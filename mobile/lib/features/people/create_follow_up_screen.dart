import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/relvio_back_button.dart';
import 'create_follow_up_controller.dart';

/// Native Relvio form for the current Person only (no Person picker — the
/// Person is implicit from the /people/:personId/follow-ups/create route).
/// Renders only the fields real Create Follow-Up authority accepts: Title
/// (required), Description (optional), Due Date & Time (optional). No status
/// picker — new Follow-ups are always server-derived PENDING. No assignee
/// input — no authoritative organization-member read boundary exists yet
/// (Product Task 043's assignee ruling); the backend field remains optional
/// and is simply never sent.
///
/// Due Date & Time (Product Task 043A): FollowUp.dueDate is an absolute
/// instant, not a date-only value like Person.dateOfBirth. A due value only
/// exists once the user has explicitly selected BOTH a calendar date AND a
/// wall-clock time — there is no default time (no midnight, no noon, no
/// current-time). See _DueDateTimeField below.
class CreateFollowUpScreen extends ConsumerStatefulWidget {
  const CreateFollowUpScreen({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<CreateFollowUpScreen> createState() => _CreateFollowUpScreenState();
}

class _CreateFollowUpScreenState extends ConsumerState<CreateFollowUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _cancel() {
    ref.read(createFollowUpControllerProvider(widget.personId).notifier).cancel();
    if (context.canPop()) context.pop();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(createFollowUpControllerProvider(widget.personId).notifier)
        .submit(title: _titleController.text, description: _descriptionController.text, dueDate: _dueDate);
  }

  String? _titleValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Title is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createFollowUpControllerProvider(widget.personId));

    ref.listen(createFollowUpControllerProvider(widget.personId), (previous, next) {
      final shouldPop = next.status == CreateFollowUpSubmitStatus.success || next.shouldClose;
      if (shouldPop && context.canPop()) {
        context.pop();
      }
    });

    final submitting = state.status == CreateFollowUpSubmitStatus.submitting;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        ref.read(createFollowUpControllerProvider(widget.personId).notifier).cancel();
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
                    'Create Follow-up.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Schedule a follow-up for this person.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  LabeledTextField(
                    label: 'Title',
                    hintText: 'Enter a title',
                    controller: _titleController,
                    validator: _titleValidator,
                  ),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    label: 'Description',
                    hintText: 'Add details (optional)',
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 16),
                  _DueDateTimeField(value: _dueDate, onChanged: (value) => setState(() => _dueDate = value)),
                  if (state.status == CreateFollowUpSubmitStatus.error) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Could not create this follow-up. Please try again.',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Save Follow-up', onPressed: submitting ? null : _submit, loading: submitting),
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

/// Sequentially opens a native date picker then a native time picker (the
/// same showDatePicker convention add_person_screen.dart's
/// _DateOfBirthField already establishes, extended with showTimePicker since
/// Follow-up.dueDate — unlike Person.dateOfBirth — is an absolute instant,
/// not a date-only value).
///
/// [value] is null exactly when no due value has been selected. It only
/// ever holds a fully-resolved local DateTime: the user's own explicitly
/// selected calendar date AND wall-clock time combined. There is no
/// intermediate "date chosen, time pending" state exposed to the parent —
/// if the user cancels the date step, or completes the date step but then
/// cancels the time step, [onChanged] is never called and whatever value
/// existed before this pick attempt (null, or a previously-confirmed
/// complete value) is left exactly as it was. This guarantees a partial
/// selection can never be held or submitted as an invented due instant, and
/// that no default time (midnight/noon/current-time) is ever chosen on the
/// user's behalf (Product Task 043A's due-instant ruling).
///
/// A trailing clear (×) affordance removes an existing selection entirely,
/// distinct from re-opening the picker.
class _DueDateTimeField extends StatelessWidget {
  const _DueDateTimeField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  static const _monthNames = [
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

  static String _format(DateTime dateTime) {
    final datePart = '${_monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final hour12Raw = dateTime.hour % 12;
    final hour12 = hour12Raw == 0 ? 12 : hour12Raw;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$datePart, $hour12:$minute $period';
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    // Cancelled at the date step: no change at all, regardless of whether a
    // value already existed.
    if (pickedDate == null) return;

    if (!context.mounted) return;
    final initialTime = value != null ? TimeOfDay(hour: value!.hour, minute: value!.minute) : TimeOfDay.now();
    final pickedTime = await showTimePicker(context: context, initialTime: initialTime);
    // Cancelled at the time step: the date-only partial selection is
    // discarded entirely — never held as an incomplete state, never
    // defaulted to midnight/noon/current-time, never submitted.
    if (pickedTime == null) return;

    onChanged(DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due Date & Time',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        InkWell(
          key: const Key('createFollowUpDueDateTimeField'),
          borderRadius: borderRadius,
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              suffixIcon: value != null
                  ? IconButton(
                      key: const Key('createFollowUpClearDueDateTimeField'),
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                      onPressed: () => onChanged(null),
                    )
                  : const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Text(
              value != null ? _format(value!) : 'Select date & time (optional)',
              style: TextStyle(fontSize: 14, color: value != null ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
