import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/brand_mark.dart';
import '../../app/widgets/primary_button.dart';

/// Matches design/ui-reference/2.png's "Welcome to Relvio" composition —
/// the pre-auth entry-actions screen reached after the onboarding carousel
/// (Product Task 077), whether by finishing it or by tapping Skip.
///
/// "Create an Organization" begins the real journey toward that outcome: it
/// routes to Create Account, since the actual POST /organizations call only
/// exists authenticated and org-less accounts are auto-routed into
/// Organization Setup right after signing in (Product Task 072/074) — it
/// never fabricates an organization or a session here. "Join Your
/// Organization" is omitted: no Invitation model or join workflow is
/// approved v1 backend authority (Product Task 071's read-only audit), so
/// there is nothing real to wire it to. "Already a member? Sign In" routes
/// to the real Sign In screen.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: BrandMark(size: 88)),
                const SizedBox(height: 24),
                Text.rich(
                  textAlign: TextAlign.center,
                  const TextSpan(
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    children: [
                      TextSpan(text: 'Welcome to '),
                      TextSpan(text: 'Relvio', style: TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Build stronger relationships.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manage people, events, attendance, and communication from one intelligent platform.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),
                PrimaryButton(label: 'Create an Organization', onPressed: () => context.go(createAccountPath)),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(signInPath),
                    child: const Text('Already a member? Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
