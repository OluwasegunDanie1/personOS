import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/brand_mark.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import 'organization_context_controller.dart';

/// Matches design/ui-reference/5.png's "Set up your organization."
/// composition. The reference also shows an Organization Logo upload,
/// Organization Type, Country, and Time Zone field — none of those exist
/// on the approved CreateOrganizationDto (name only), so only the
/// Organization Name field is implemented. "Skip for now" is also omitted:
/// the router requires an active organization to reach the primary shell,
/// so skipping would strand the user with no way forward. On success,
/// navigates explicitly to organizationReadyPath (Product Task 077) rather
/// than relying on the router's own redirect, so the completion screen is
/// never skipped.
class OrganizationSetupScreen extends ConsumerStatefulWidget {
  const OrganizationSetupScreen({super.key});

  @override
  ConsumerState<OrganizationSetupScreen> createState() => _OrganizationSetupScreenState();
}

class _OrganizationSetupScreenState extends ConsumerState<OrganizationSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(organizationContextControllerProvider.notifier).createOrganization(_nameController.text.trim());

      if (!mounted) return;
      context.go(organizationReadyPath);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not create the organization. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandMark(size: 96)),
                  const SizedBox(height: 24),
                  const Text(
                    'Set up your organization.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tell us a little about your organization to personalize your workspace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 28),
                  PrimaryButton(label: 'Continue', onPressed: _submit, loading: _submitting),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
