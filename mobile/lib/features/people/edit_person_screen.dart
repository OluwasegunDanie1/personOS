import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import 'edit_person_controller.dart';
import 'people_models.dart';

/// No direct Edit Person reference exists anywhere in design/ui-reference
/// (Product Task 047's frozen-UI inspection: only Person Profile — 7.png
/// panel 2 — and Add Person — 7.png panel 3 — appear; "My Profile" — 12.png
/// panel 2 — is the signed-in User's own account settings, a different
/// domain entirely). This screen therefore follows the accepted fallback
/// authority: the same native Relvio form language Add Person and Create
/// Follow-up already establish (numbered-free flat form, LabeledTextField,
/// PrimaryButton, bordered dropdown/date fields) — no redesign, no new
/// visual system.
///
/// Renders only the 8 fields Update Person's PATCH contract accepts
/// (Product Task 045): First Name, Last Name, Email, Phone, Status, Gender,
/// Date of Birth, Address. No avatar/tags/Journey editor, no Person picker,
/// no delete/archive action. Initial values come exclusively from this
/// screen's own independent GET Detail load (EditPersonController) — never
/// from People Directory summary data or route-passed state.
class EditPersonScreen extends ConsumerStatefulWidget {
  const EditPersonScreen({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<EditPersonScreen> createState() => _EditPersonScreenState();
}

class _EditPersonScreenState extends ConsumerState<EditPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  PersonStatus _status = PersonStatus.active;
  PersonGender? _gender;
  DateTime? _dateOfBirth;

  /// True once the form controls have been populated from the real, loaded
  /// Person Detail. Guards against a later state change (e.g. this screen's
  /// own retryLoad after a load failure) ever clobbering values the user has
  /// already started editing.
  bool _hydrated = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _hydrate(PersonDetail detail) {
    _firstNameController.text = detail.firstName;
    _lastNameController.text = detail.lastName;
    _emailController.text = detail.email ?? '';
    _phoneController.text = detail.phone ?? '';
    _addressController.text = detail.address ?? '';
    _status = detail.status;
    _gender = detail.gender;
    _dateOfBirth = detail.dateOfBirth;
    _hydrated = true;
  }

  void _cancel() {
    ref.read(editPersonControllerProvider(widget.personId).notifier).cancel();
    if (context.canPop()) context.pop();
  }

  void _setStatus(PersonStatus value) => setState(() => _status = value);

  void _setGender(PersonGender? value) => setState(() => _gender = value);

  void _setDateOfBirth(DateTime? value) => setState(() => _dateOfBirth = value);

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(editPersonControllerProvider(widget.personId).notifier)
        .submit(
          EditPersonFormValues(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            status: _status,
            gender: _gender,
            dateOfBirth: _dateOfBirth,
            address: _addressController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editPersonControllerProvider(widget.personId));

    ref.listen(editPersonControllerProvider(widget.personId), (previous, next) {
      if (next.loadStatus == EditPersonLoadStatus.loaded && !_hydrated && next.detail != null) {
        setState(() => _hydrate(next.detail!));
      }

      final shouldPop = next.submitStatus == EditPersonSubmitStatus.success || next.shouldClose;
      if (shouldPop && context.canPop()) {
        context.pop();
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        ref.read(editPersonControllerProvider(widget.personId).notifier).cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: IconButton(
                  onPressed: _cancel,
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(child: _Body(personId: widget.personId, state: state, screenState: this)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.personId, required this.state, required this.screenState});

  final String personId;
  final EditPersonState state;
  final _EditPersonScreenState screenState;

  @override
  Widget build(BuildContext context) {
    switch (state.loadStatus) {
      case EditPersonLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case EditPersonLoadStatus.error:
        return _LoadErrorState(
          onRetry: () => screenState.ref.read(editPersonControllerProvider(personId).notifier).retryLoad(),
        );
      case EditPersonLoadStatus.loaded:
        return _EditForm(personId: personId, state: state, screenState: screenState);
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

class _EditForm extends StatelessWidget {
  const _EditForm({required this.personId, required this.state, required this.screenState});

  final String personId;
  final EditPersonState state;
  final _EditPersonScreenState screenState;

  @override
  Widget build(BuildContext context) {
    final submitting = state.submitStatus == EditPersonSubmitStatus.submitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: screenState._formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit person.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              "Update this person's profile details.",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabeledTextField(
                    label: 'First Name',
                    hintText: 'Enter first name',
                    controller: screenState._firstNameController,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'First name is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabeledTextField(
                    label: 'Last Name',
                    hintText: 'Enter last name',
                    controller: screenState._lastNameController,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Last name is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Email Address',
              hintText: 'Enter email address',
              controller: screenState._emailController,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: screenState._emailValidator,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Phone Number',
              hintText: 'Enter phone number',
              controller: screenState._phoneController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StatusField(value: screenState._status, onChanged: screenState._setStatus),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderField(value: screenState._gender, onChanged: screenState._setGender),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DateOfBirthField(value: screenState._dateOfBirth, onChanged: screenState._setDateOfBirth),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Address',
              hintText: 'Enter address',
              controller: screenState._addressController,
              icon: Icons.location_on_outlined,
            ),
            if (state.submitStatus == EditPersonSubmitStatus.error) ...[
              const SizedBox(height: 12),
              Text(
                state.submitErrorMessage ?? 'Could not save these changes. Please try again.',
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            if (state.submitStatus == EditPersonSubmitStatus.noChange) ...[
              const SizedBox(height: 12),
              const Text('No changes to save.', style: TextStyle(color: AppColors.textSecondary)),
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
                onPressed: screenState._cancel,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusField extends StatelessWidget {
  const _StatusField({required this.value, required this.onChanged});

  final PersonStatus value;
  final ValueChanged<PersonStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PersonStatus>(
          key: const Key('editPersonStatusField'),
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(borderRadius: borderRadius, borderSide: const BorderSide(color: AppColors.borderSubtle)),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
            ),
          ),
          items: const [
            DropdownMenuItem(value: PersonStatus.active, child: Text('Active')),
            DropdownMenuItem(value: PersonStatus.inactive, child: Text('Inactive')),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ],
    );
  }
}

/// Unlike Add Person's gender field (which starts unanswered and has no need
/// to go back to "no answer"), Edit Person's initial value may already be
/// MALE/FEMALE and the user must be able to truthfully return it to unset —
/// so, unlike Add Person, this field's own item list includes an explicit
/// "Not specified" entry representing null. This is a UI label only: it is
/// never serialized as a backend enum value (no OTHER/UNSPECIFIED/NONE
/// authority exists) — selecting it simply sets the local gender value to
/// null, which EditPersonController then sends as an explicit JSON null
/// clear (or omits entirely, if the loaded Person's gender was already
/// null).
class _GenderField extends StatelessWidget {
  const _GenderField({required this.value, required this.onChanged});

  final PersonGender? value;
  final ValueChanged<PersonGender?> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PersonGender?>(
          key: const Key('editPersonGenderField'),
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(borderRadius: borderRadius, borderSide: const BorderSide(color: AppColors.borderSubtle)),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
            ),
          ),
          items: const [
            DropdownMenuItem<PersonGender?>(value: null, child: Text('Not specified')),
            DropdownMenuItem(value: PersonGender.male, child: Text('Male')),
            DropdownMenuItem(value: PersonGender.female, child: Text('Female')),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Date-only picker (no time picker — dateOfBirth is a calendar date, not an
/// absolute instant, unlike Follow-up.dueDate). A trailing clear (×)
/// affordance lets the user truthfully remove an existing date of birth,
/// mirroring create_follow_up_screen.dart's _DueDateTimeField clear
/// convention. Uses the same firstDate/lastDate bounds as Add Person's own
/// _DateOfBirthField — no stricter business rule is invented here.
class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({required this.value, required this.onChanged});

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

  static String _format(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        InkWell(
          key: const Key('editPersonDateOfBirthField'),
          borderRadius: borderRadius,
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              suffixIcon: value != null
                  ? IconButton(
                      key: const Key('editPersonClearDateOfBirthField'),
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                      onPressed: () => onChanged(null),
                    )
                  : const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
              border: OutlineInputBorder(borderRadius: borderRadius, borderSide: const BorderSide(color: AppColors.borderSubtle)),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Text(
              value != null ? _format(value!) : 'Select date',
              style: TextStyle(fontSize: 14, color: value != null ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
