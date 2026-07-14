import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../auth/auth_models.dart';
import '../auth/auth_session_controller.dart';
import '../organizations/organization_context_controller.dart';
import '../organizations/organization_models.dart';

/// Matches design/ui-reference/12.png's "My Profile" identity block and
/// red-outline Log Out action. The reference's full "More" menu also lists
/// Integrations, Security, Appearance, Reports & Analytics, Billing,
/// Settings, Help Center, and About — none of those have an approved
/// backend capability, so rendering them (even disabled) would visually
/// promise functionality this build does not have. Organization Members and
/// Roles & Permissions are now real, interactive entries (Product Task 052,
/// integrating Product Task 050's read-only API authority); everything else
/// remains identity display, organization switching (client-side context
/// per 16_Security.md), and logout.
class WorkspaceScreen extends ConsumerWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionControllerProvider);
    final organizationContext = ref.watch(organizationContextControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: const Text('Workspace', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user != null) _ProfileCard(user: user),
          const SizedBox(height: 24),
          if (organizationContext is OrganizationContextActive)
            _OrganizationSection(context: organizationContext, ref: ref),
          const SizedBox(height: 24),
          const _ManageOrganizationSection(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => ref.read(authSessionControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    final initials = '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${user.firstName} ${user.lastName}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _OrganizationSection extends StatelessWidget {
  const _OrganizationSection({required this.context, required this.ref});

  final OrganizationContextActive context;
  final WidgetRef ref;

  @override
  Widget build(BuildContext buildContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organization',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              for (final organization in context.organizations)
                _OrganizationTile(
                  organization: organization,
                  isSelected: organization.id == context.selectedOrganizationId,
                  onTap: () =>
                      ref.read(organizationContextControllerProvider.notifier).selectOrganization(organization.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrganizationTile extends StatelessWidget {
  const _OrganizationTile({required this.organization, required this.isSelected, required this.onTap});

  final OrganizationSummary organization;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        child: const Icon(Icons.apartment_outlined, color: AppColors.brandPrimary),
      ),
      title: Text(organization.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      subtitle: Text(organization.role.name, style: const TextStyle(color: AppColors.textSecondary)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.brandPrimary) : null,
    );
  }
}

/// Matches design/ui-reference/12.png's "More" menu list-item style (icon
/// circle, title, subtitle, trailing chevron) for the two now-real entries:
/// Organization Members and Roles & Permissions (Product Task 052).
/// Integrations and every other frozen "More" menu item remain omitted —
/// none has an approved backend capability.
class _ManageOrganizationSection extends StatelessWidget {
  const _ManageOrganizationSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organization',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              _ManageOrganizationTile(
                icon: Icons.groups_outlined,
                title: 'Organization Members',
                subtitle: 'View everyone with access to this organization',
                onTap: () => context.push('/workspace/members'),
              ),
              const Divider(height: 1),
              _ManageOrganizationTile(
                icon: Icons.shield_outlined,
                title: 'Roles & Permissions',
                subtitle: 'View roles and their real assigned permissions',
                onTap: () => context.push('/workspace/roles'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManageOrganizationTile extends StatelessWidget {
  const _ManageOrganizationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        child: Icon(icon, color: AppColors.brandPrimary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}
