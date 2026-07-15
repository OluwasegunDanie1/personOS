import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/relvio_back_button.dart';
import 'organization_context_controller.dart';

/// Matches design/ui-reference/12.png's "Organization" screen title only
/// (Product Task 080). The frozen screen also shows Organization Logo
/// upload, Theme Color, Organization Type, Country, Time Zone, Language,
/// Journey Stages, Event Categories, Member ID Format, Attendance Rules,
/// Default Check-In Method, and Notification toggles — none of those is
/// approved backend authority: PATCH /organizations/:organizationId accepts
/// only { name } (Product Task 079's audit). This screen therefore edits
/// only the real Organization Name field.
///
/// Renders a truthful loading/error/unavailable state until a real active
/// organization context exists (Product Task 088) — it never silently
/// initializes the form with an empty organization id/name, which
/// previously rendered as a blank, seemingly-stuck field.
class EditOrganizationScreen extends ConsumerStatefulWidget {
  const EditOrganizationScreen({super.key});

  @override
  ConsumerState<EditOrganizationScreen> createState() => _EditOrganizationScreenState();
}

class _EditOrganizationScreenState extends ConsumerState<EditOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameController;
  String? _organizationId;
  String? _originalName;

  bool _submitting = false;
  String? _errorMessage;
  bool _saved = false;

  @override
  void dispose() {
    _nameController?.dispose();
    super.dispose();
  }

  /// Hydrates the form from the real active organization the first time it
  /// becomes available. A no-op on later rebuilds so in-progress edits are
  /// never clobbered.
  void _hydrateFrom(OrganizationContextActive context) {
    if (_nameController != null) return;

    _organizationId = context.selected.id;
    _originalName = context.selected.name;
    _nameController = TextEditingController(text: _originalName);
    // A further edit after a successful save should clear the stale "Saved."
    // confirmation and any prior error — never leave truthful feedback about
    // a previous submission attached to unsaved new input.
    _nameController!.addListener(() {
      if (_saved || _errorMessage != null) {
        setState(() {
          _saved = false;
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final nameController = _nameController;
    final organizationId = _organizationId;
    final originalName = _originalName;
    if (nameController == null || organizationId == null || originalName == null) return;

    final newName = nameController.text.trim();
    // Defense in depth: the Save button is already disabled when unchanged
    // (see build()), but never send a no-op request even if invoked another way.
    if (newName == originalName) return;

    final current = ref.read(organizationContextControllerProvider);
    final stillOnSameOrganization =
        current is OrganizationContextActive && current.selectedOrganizationId == organizationId;
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
          .updateOrganizationName(organizationId: organizationId, name: newName);

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
    final organizationContext = ref.watch(organizationContextControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: RelvioBackButton(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Organization',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildBody(organizationContext)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(OrganizationContextState organizationContext) {
    return switch (organizationContext) {
      OrganizationContextRestoring() => const Center(child: CircularProgressIndicator()),
      OrganizationContextFailure() => _StatusState(
        message: 'Could not load your organization.',
        action: OutlinedButton(
          onPressed: () => ref.read(organizationContextControllerProvider.notifier).restore(),
          child: const Text('Retry'),
        ),
      ),
      OrganizationContextEmpty() => const _StatusState(message: 'No active organization is available right now.'),
      OrganizationContextActive() => _buildForm(organizationContext),
    };
  }

  Widget _buildForm(OrganizationContextActive organizationContext) {
    _hydrateFrom(organizationContext);
    final nameController = _nameController!;
    final originalName = _originalName!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledTextField(
              label: 'Organization Name',
              hintText: 'Enter organization name',
              controller: nameController,
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
              valueListenable: nameController,
              builder: (context, value, _) {
                final hasChange = value.text.trim().isNotEmpty && value.text.trim() != originalName;
                return PrimaryButton(label: 'Save Changes', onPressed: hasChange ? _submit : null, loading: _submitting);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusState extends StatelessWidget {
  const _StatusState({required this.message, this.action});

  final String message;
  final Widget? action;

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
