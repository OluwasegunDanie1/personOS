import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/primary_button.dart';

/// Matches design/ui-reference/5.png's third panel, "Your organization is
/// ready!" — reached only after OrganizationSetupScreen's real
/// POST /organizations call succeeds and organizationContextControllerProvider
/// has already transitioned to OrganizationContextActive (Product Task 077).
/// This screen never fabricates organization state itself; it is purely a
/// truthful confirmation of a creation that already happened.
///
/// The frozen panel also shows an "Invite More Members" action — omitted
/// here since no Invitation/member-invite endpoint is approved v1 backend
/// authority (Product Task 071). Only "Go to Dashboard" (the real, required
/// continuation) is implemented.
class OrganizationReadyScreen extends StatelessWidget {
  const OrganizationReadyScreen({super.key});

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
                Image.asset('assets/brand/Ready.png', height: 220),
                const SizedBox(height: 24),
                const Text(
                  'Your organization is ready!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                const Text(
                  "You're all set. Start managing people, events, attendance, communication, and relationships with Relvio.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                PrimaryButton(label: 'Go to Dashboard', onPressed: () => context.go(shellPaths.first)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
