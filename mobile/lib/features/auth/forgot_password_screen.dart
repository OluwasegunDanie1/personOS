import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/brand_mark.dart';
import '../../app/widgets/labeled_text_field.dart';
import '../../app/widgets/primary_button.dart';
import '../../core/providers.dart';

/// Matches design/ui-reference/4.png's "Forgot your password?" composition:
/// Email field, Send Reset Link button, back-to-Sign-In link (Product Task
/// 072/074). No boxed back button: the frozen panel shows none, and
/// "← Back to Sign In" is the real, sole way back (Product Task 090A).
/// Always shows the same non-disclosing success message the real
/// API returns — never a claim that an email was actually sent, since no
/// email delivery integration exists. Outside production, the API also
/// returns developmentResetToken; when present, a clearly labelled
/// DEVELOPMENT ONLY block (not part of the frozen reference) offers a real
/// path into Reset Password with that token pre-filled — this is a
/// controlled dev/testing affordance, never presented as production
/// delivery.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _submitting = false;
  String? _successMessage;
  String? _developmentResetToken;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmed)) return 'Enter a valid email address';
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
      final result = await ref.read(authApiProvider).forgotPassword(email: _emailController.text.trim());

      if (!mounted) return;
      setState(() {
        _successMessage = result.message;
        _developmentResetToken = result.developmentResetToken;
      });
    } catch (_) {
      if (!mounted) return;
      // The real endpoint itself never distinguishes failure modes for an
      // unknown email, but a genuine transport/server error is still a
      // real failure to surface — never silently swallowed.
      setState(() => _errorMessage = 'Could not process your request. Please try again.');
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
                    'Forgot your password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enter your email address and we'll send you a secure reset link.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  if (_successMessage == null) ...[
                    LabeledTextField(
                      label: 'Email Address',
                      hintText: 'Enter your email',
                      controller: _emailController,
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
                    ],
                    const SizedBox(height: 28),
                    PrimaryButton(label: 'Send Reset Link', onPressed: _submit, loading: _submitting),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_developmentResetToken != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        key: const Key('developmentResetTokenBlock'),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DEVELOPMENT ONLY',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'No email is sent in this environment. Use this real reset token directly for testing.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => context.push(resetPasswordPath, extra: _developmentResetToken),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD97706),
                                  side: const BorderSide(color: Color(0xFFD97706)),
                                ),
                                child: const Text('Continue to Reset Password (dev)'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
