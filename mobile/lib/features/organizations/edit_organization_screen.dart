import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import 'organization_context_controller.dart';

/// Matches design/ui-reference/12.png's "Organization" screen title only
/// (Product Task 080). The frozen screen also shows Organization Logo
/// upload, Theme Color, Organization Type, Country, Time Zone, Language,
/// Journey Stages, Event Categories, Member ID Format, Attendance Rules,
/// Default Check-In Method, and Notification toggles — none of those is
/// approved backend authority: PATCH /organizations/:organizationId accepts
/// only { name } (Product Task 079's audit). This screen therefore edits
/// only the real Organization Name field.
class EditOrganizationScreen extends ConsumerStatefulWidget {
  const EditOrganizationScreen({super.key});

  @override
  ConsumerState<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends ConsumerState<EditOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final String _organizationId;
  late final String _originalName;

  bool _submitting = false;
  String? _errorMessage;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final context = ref.read(organizationContextControllerProvider);
    final selected = context is OrganizationContextActive ? context.selected : null;
    _organizationId = selected?.id ?? '';
    _originalName = selected?.name ?? '';
    _nameController = TextEditingController(text: _originalName);
    // A further edit after a successful save should clear the stale "Saved."
    // confirmation and any prior error — never leave truthful feedback about
    // a previous submission attached to unsaved new input.
    _nameController.addListener(() {
      if (_saved || _errorMessage != null) {
        setState(() {
          _saved = false;
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    // Defense in depth: the Save button is already disabled when unchanged
    // (see build()), but never send a no-op request even if invoked another way.
    if (newName == _originalName) return;

    final current = ref.read(organizationContextControllerProvider);
    final stillOnSameOrganization =
        current is OrganizationContextActive && current.selectedOrganizationId == _organizationId;
    if (!stillOnSameOrganization) {
      setState(() => _errorMessage = 'Your active organization changed. Please try again.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _saved = false;
    });

    try {
      await ref
          .read(organizationContextControllerProvider.notifier)
          .updateOrganizationName(organizationId: _organizationId, name: newName);

      if (!mounted) return;
      setState(() => _saved = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not update the organization name. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: const Text(
                'Organization',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabeledTextField(
                        label: 'Organization Name',
                        hintText: 'Enter organization name',
                        controller: _nameController,
                        icon: Icons.apartment_outlined,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Organization name is required' : null,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
                      ],
                      if (_saved) ...[
                        const SizedBox(height: 16),
                        const Text('Saved.', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                      ],
                      const SizedBox(height: 24),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nameController,
                        builder: (context, value, _) {
                          final hasChange = value.text.trim().isNotEmpty && value.text.trim() != _originalName;
                          return PrimaryButton(
                            label: 'Save Changes',
                            onPressed: hasChange ? _submit : null,
                            loading: _submitting,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
