import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/brand_mark.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import 'organization_context_controller.dart';

/// Formats the device's real UTC offset as e.g. "UTC+01:00" (Product Task
/// 092). This app has no IANA timezone database and adds none (no new
/// package) — this is the one truthful value derivable from `dart:core`
/// alone, and it is never presented as a named IANA zone the user "selected".
String autoDetectedUtcOffset({DateTime? now}) {
  final offset = (now ?? DateTime.now()).timeZoneOffset;
  final totalMinutes = offset.inMinutes;
  final sign = totalMinutes < 0 ? '-' : '+';
  final absMinutes = totalMinutes.abs();
  final hours = (absMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (absMinutes % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hours:$minutes';
}

/// Matches design/ui-reference/5.png's "Set up your organization."
/// composition (Product Task 092, correcting Task 090B's audit): Organization
/// Logo, Organization Name, Organization Type, Country, and Time Zone are all
/// now real, since PATCH/POST /organizations accepts industry/country/
/// timezone in addition to name. Organization Logo remains a truthful
/// non-actionable "coming soon" block — real upload/storage infrastructure
/// does not exist and is out of scope here; no fake picker, no fabricated
/// success. Organization Type and Country use plain text fields, not
/// dropdowns: no approved finite list/enum exists for either anywhere in
/// project authority (Product Task 092's own audit), so presenting fixed
/// categories would fabricate a taxonomy that isn't real. Time Zone is
/// pre-filled with the device's real UTC offset (dart:core only, no new
/// timezone package) and remains editable — the user is never told they
/// picked a named IANA zone the app cannot actually determine or store.
/// "Skip for now" is not implemented: Relvio's routing requires an active
/// organization context, and there is no org-less Dashboard state to skip
/// into (Product Task 090B ruling). On success, navigates explicitly to
/// organizationReadyPath (Product Task 077/090B) rather than relying on the
/// router's own redirect, so the completion screen is never skipped.
class OrganizationSetupScreen extends ConsumerStatefulWidget {
  const OrganizationSetupScreen({super.key});

  @override
  ConsumerState<OrganizationSetupScreen> createState() => _OrganizationSetupScreenState();
}

class _OrganizationSetupScreenState extends ConsumerState<OrganizationSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _industryController = TextEditingController();
  final _countryController = TextEditingController();
  late final TextEditingController _timezoneController;

  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _timezoneController = TextEditingController(text: autoDetectedUtcOffset());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _countryController.dispose();
    _timezoneController.dispose();
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
      await ref
          .read(organizationContextControllerProvider.notifier)
          .createOrganization(
            _nameController.text.trim(),
            industry: _industryController.text.trim(),
            country: _countryController.text.trim(),
            timezone: _timezoneController.text.trim(),
          );

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
                  const SizedBox(height: 28),
                  const _OrganizationLogoUnavailableArea(),
                  const SizedBox(height: 20),
                  LabeledTextField(
                    label: 'Organization Name',
                    hintText: 'Enter organization name',
                    controller: _nameController,
                    icon: Icons.apartment_outlined,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Organization name is required' : null,
                  ),
                  const SizedBox(height: 20),
                  LabeledTextField(
                    label: 'Organization Type',
                    hintText: 'e.g. Church, School, Business, NGO',
                    controller: _industryController,
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 20),
                  LabeledTextField(
                    label: 'Country',
                    hintText: 'Enter your country',
                    controller: _countryController,
                    icon: Icons.public_outlined,
                  ),
                  const SizedBox(height: 20),
                  LabeledTextField(
                    label: 'Time Zone',
                    hintText: 'UTC offset',
                    controller: _timezoneController,
                    icon: Icons.schedule_outlined,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Automatically detected from your device. You can edit it if needed.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

/// A truthful, non-actionable "coming soon" treatment for the frozen
/// Organization Logo / Upload logo area (Product Task 092). No file picker,
/// no fabricated upload success, no submitted value — real upload/storage
/// infrastructure does not exist yet. The visual composition is kept present
/// (not stripped) so the approved layout isn't silently removed.
class _OrganizationLogoUnavailableArea extends StatelessWidget {
  const _OrganizationLogoUnavailableArea();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organization Logo',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, color: AppColors.textSecondary),
              SizedBox(height: 8),
              Text(
                'Logo upload coming soon',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
