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

/// No direct frozen reference exists for a token-entry Reset Password step
/// (design/ui-reference/4.png only shows the Forgot-Password "send" step),
/// so this screen follows the accepted fallback: the same native Relvio
/// form language every other unreferenced screen uses (Product Task 047's
/// precedent for Edit Person). [prefilledToken] is optionally supplied when
/// reached from Forgot Password's DEVELOPMENT ONLY path; it is never
/// required, and this screen never assumes email delivery exists.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.prefilledToken});

  final String? prefilledToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _submitting = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.prefilledToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _newPasswordValidator(String? value) {
    if (value == null || value.isEmpty) return 'New password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your new password';
    if (value != _newPasswordController.text) return 'Passwords do not match';
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
      // Real password reset only — never a fabricated session. The user
      // must sign in afterward with the new password.
      await ref
          .read(authApiProvider)
          .resetPassword(token: _tokenController.text.trim(), newPassword: _newPasswordController.text);

      if (!mounted) return;
      context.go(signInPath, extra: 'Password reset successful. Please sign in.');
    } on ApiException catch (error) {
      if (!mounted) return;
      // INVALID_RESET_TOKEN covers an absent, expired, or already-used
      // token identically — never distinguished, matching the backend's
      // own non-disclosure convention exactly.
      setState(() {
        _errorMessage = error.code == 'INVALID_RESET_TOKEN'
            ? 'This reset link is invalid or has expired. Please request a new one.'
            : 'Could not reset your password. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not reset your password. Please try again.');
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
                    'Reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your reset token and choose a new password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  LabeledTextField(
                    label: 'Reset Token',
                    hintText: 'Paste your reset token',
                    controller: _tokenController,
                    icon: Icons.vpn_key_outlined,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Reset token is required' : null,
                  ),
                  const SizedBox(height: 20),
                  LabeledTextField(
                    label: 'New Password',
                    hintText: 'Enter a new password',
                    controller: _newPasswordController,
                    icon: Icons.lock_outline,
                    obscureText: _obscureNewPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                    validator: _newPasswordValidator,
                  ),
                  const SizedBox(height: 20),
                  LabeledTextField(
                    label: 'Confirm New Password',
                    hintText: 'Re-enter your new password',
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: _confirmPasswordValidator,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 28),
                  PrimaryButton(label: 'Reset Password', onPressed: _submit, loading: _submitting),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(signInPath),
                      child: const Text('← Back to Sign In'),
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
