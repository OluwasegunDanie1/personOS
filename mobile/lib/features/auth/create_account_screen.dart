import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/brand_mark.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/relvio_back_button.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/providers.dart';

/// Adapts design/ui-reference/4.png's "Create your organization." panel to
/// the real, narrower POST /auth/register contract (Product Task 072/074):
/// First Name, Last Name, Email, Password only. The frozen panel also shows
/// an Organization Name field and a Confirm Password field, and its footer
/// link reads "Create Organization" — none of that matches what this
/// endpoint actually does (it creates a User only, never an Organization,
/// and never auto-logs in), so this screen is truthfully titled "Create
/// your account." and labelled "Create Account" throughout rather than
/// reusing the frozen "Create Organization" wording, which would
/// misrepresent the action. Organization creation remains its own separate,
/// already-implemented, authenticated step (OrganizationSetupScreen).
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      // Real account creation only — never a fabricated session, never an
      // auto-created Organization. The user must sign in afterward.
      await ref.read(authApiProvider).register(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      context.go(signInPath, extra: 'Account created. Please sign in.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = switch (error.code) {
          'EMAIL_ALREADY_REGISTERED' => 'An account with this email already exists.',
          // Real rate limiting (POST /auth/register is throttled to 5 per 15
          // minutes) — never fabricate a successful registration, and never
          // hide the true cause behind the generic message (Product Task 088).
          'TOO_MANY_REQUESTS' => 'Too many attempts. Please wait a few minutes and try again.',
          _ => 'Could not create your account. Please try again.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not create your account. Please try again.');
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RelvioBackButton(
                      onPressed: () => context.canPop() ? context.pop() : context.go(signInPath),
                    ),
                  ),
                  const Center(child: BrandMark(size: 96)),
                  const SizedBox(height: 24),
                  const Text(
                    'Create your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get started with Relvio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledTextField(
                          label: 'First Name',
                          hintText: 'Enter first name',
                          controller: _firstNameController,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'First name is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledTextField(
                          label: 'Last Name',
                          hintText: 'Enter last name',
                          controller: _lastNameController,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Last name is required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LabeledTextField(
                    label: 'Email Address',
                    hintText: 'Enter your email',
                    controller: _emailController,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 20),
                  LabeledTextField(
                    label: 'Password',
                    hintText: 'Create a password',
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: _passwordValidator,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 28),
                  PrimaryButton(label: 'Create Account', onPressed: _submit, loading: _submitting),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _submitting ? null : () => context.go(signInPath),
                      child: const Text('Already have an account? Sign In'),
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
