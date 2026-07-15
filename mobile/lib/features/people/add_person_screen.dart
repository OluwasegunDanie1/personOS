import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/relvio_back_button.dart';
import 'add_person_controller.dart';
import 'people_models.dart';

/// Matches design/ui-reference/7.png's numbered four-card accordion "Add a
/// new person." composition (superseding Task 033's flat-form attempt at
/// design/ui-reference/6.png's composition, per controller ruling). Renders
/// only the fields the approved Create Person API accepts: First Name, Last
/// Name, Gender, Date of Birth, Phone Number, Email Address, Address,
/// Status. Profile Photo, Group, and Notes input are visual-conformance
/// debt pending media/upload, Group-domain, and Notes-backend authority
/// respectively — none is rendered as a fake/disabled control.
class AddPersonScreen extends ConsumerStatefulWidget {
  const AddPersonScreen({super.key});

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  PersonStatus _status = PersonStatus.active;
  PersonGender? _gender;
  DateTime? _dateOfBirth;

  bool _basicExpanded = true;
  bool _contactExpanded = false;
  bool _organizationExpanded = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _cancel() {
    ref.read(addPersonControllerProvider.notifier).cancel();
    if (context.canPop()) context.pop();
  }

  Future<void> _submit() async {
    final firstNameInvalid = _firstNameController.text.trim().isEmpty;
    final lastNameInvalid = _lastNameController.text.trim().isEmpty;
    final emailInvalid = _emailValidator(_emailController.text) != null;

    if (firstNameInvalid || lastNameInvalid) {
      setState(() => _basicExpanded = true);
    }
    if (emailInvalid) {
      setState(() => _contactExpanded = true);
    }

    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(addPersonControllerProvider.notifier)
        .submit(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          status: _status,
          gender: _gender,
          dateOfBirth: _dateOfBirth,
          address: _addressController.text,
        );
  }

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addPersonControllerProvider);

    ref.listen(addPersonControllerProvider, (previous, next) {
      final shouldPop = next.status == AddPersonSubmitStatus.success || next.shouldClose;
      if (shouldPop && context.canPop()) {
        context.pop();
      }
    });

    final submitting = state.status == AddPersonSubmitStatus.submitting;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        ref.read(addPersonControllerProvider.notifier).cancel();
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
                    'Add a new person.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create a profile to begin tracking their journey.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    number: 1,
                    title: 'Basic Information',
                    subtitle: "Add the person's basic details.",
                    expanded: _basicExpanded,
                    onToggle: () => setState(() => _basicExpanded = !_basicExpanded),
                    child: _BasicInformationContent(
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      gender: _gender,
                      onGenderChanged: (value) => setState(() => _gender = value),
                      dateOfBirth: _dateOfBirth,
                      onDateOfBirthChanged: (value) => setState(() => _dateOfBirth = value),
                    ),
                  ),
                  _SectionCard(
                    number: 2,
                    title: 'Contact Information',
                    subtitle: 'Add contact details.',
                    expanded: _contactExpanded,
                    onToggle: () => setState(() => _contactExpanded = !_contactExpanded),
                    child: _ContactInformationContent(
                      phoneController: _phoneController,
                      emailController: _emailController,
                      addressController: _addressController,
                      emailValidator: _emailValidator,
                    ),
                  ),
                  _SectionCard(
                    number: 3,
                    title: 'Organization Information',
                    subtitle: 'Add organization details.',
                    expanded: _organizationExpanded,
                    onToggle: () => setState(() => _organizationExpanded = !_organizationExpanded),
                    child: _StatusField(value: _status, onChanged: (value) => setState(() => _status = value)),
                  ),
                  const _SectionCard(
                    number: 4,
                    title: 'Notes',
                    subtitle: 'Add any additional notes.',
                    expanded: false,
                    onToggle: null,
                    child: SizedBox.shrink(),
                  ),
                  if (state.status == AddPersonSubmitStatus.error) ...[
                    const SizedBox(height: 4),
                    Text(
                      state.errorMessage ?? 'Could not save this person. Please try again.',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Save Person', onPressed: submitting ? null : _submit, loading: submitting),
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

/// Local, lightweight numbered-card accordion primitive matching the frozen
/// reference's card language. Content stays mounted (via [Offstage], not
/// conditional building) while collapsed, so entered values are never lost
/// and Form validation can still reach fields inside a collapsed card.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final int number;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback? onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _NumberBadge(number: number),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          Offstage(
            offstage: !expanded,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: child),
          ),
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
      child: Text(
        '$number',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BasicInformationContent extends StatelessWidget {
  const _BasicInformationContent({
    required this.firstNameController,
    required this.lastNameController,
    required this.gender,
    required this.onGenderChanged,
    required this.dateOfBirth,
    required this.onDateOfBirthChanged,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final PersonGender? gender;
  final ValueChanged<PersonGender?> onGenderChanged;
  final DateTime? dateOfBirth;
  final ValueChanged<DateTime?> onDateOfBirthChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledTextField(
                label: 'First Name',
                hintText: 'Enter first name',
                controller: firstNameController,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'First name is required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledTextField(
                label: 'Last Name',
                hintText: 'Enter last name',
                controller: lastNameController,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Last name is required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _GenderField(value: gender, onChanged: onGenderChanged)),
            const SizedBox(width: 12),
            Expanded(child: _DateOfBirthField(value: dateOfBirth, onChanged: onDateOfBirthChanged)),
          ],
        ),
      ],
    );
  }
}

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
        DropdownButtonFormField<PersonGender>(
          key: const Key('addPersonGenderField'),
          initialValue: value,
          isExpanded: true,
          hint: const Text('Select gender', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
            DropdownMenuItem(value: PersonGender.male, child: Text('Male')),
            DropdownMenuItem(value: PersonGender.female, child: Text('Female')),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

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

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) {
      onChanged(picked);
    }
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
          key: const Key('addPersonDateOfBirthField'),
          borderRadius: borderRadius,
          onTap: () => _pickDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
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

class _ContactInformationContent extends StatelessWidget {
  const _ContactInformationContent({
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.emailValidator,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final String? Function(String?) emailValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          label: 'Phone Number',
          hintText: 'Enter phone number',
          controller: phoneController,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        LabeledTextField(
          label: 'Email Address',
          hintText: 'Enter email address',
          controller: emailController,
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          validator: emailValidator,
        ),
        const SizedBox(height: 20),
        LabeledTextField(
          label: 'Address',
          hintText: 'Enter address',
          controller: addressController,
          icon: Icons.location_on_outlined,
        ),
      ],
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
          initialValue: value,
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
