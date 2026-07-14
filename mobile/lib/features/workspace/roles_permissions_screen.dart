import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/empty_state.dart';
import '../organizations/organization_models.dart';
import 'roles_permissions_provider.dart';

/// Matches design/ui-reference/12.png's "Roles & Permissions" screen as
/// closely as current real authority allows: a Roles list and a real
/// "Permissions for {role}" panel for the selected role. The frozen
/// reference's "Total Users / Active Roles / Custom Roles" stat row and its
/// icon-grouped "Permission Categories" (People/Events/Attendance/...) are
/// deliberately not reproduced — Role has no "system vs custom" or "active"
/// distinction, and Permission has no category/group field, so rendering
/// either would fabricate a product concept that does not exist (Product
/// Task 049/052). Read-only: no create/edit/delete-role or assign/remove-
/// permission control exists anywhere on this screen, and there is no
/// "Save Permissions" action, matching the real GET-only contract exactly.
class RolesPermissionsScreen extends ConsumerStatefulWidget {
  const RolesPermissionsScreen({super.key});

  @override
  ConsumerState<RolesPermissionsScreen> createState() => _RolesPermissionsScreenState();
}

class _RolesPermissionsScreenState extends ConsumerState<RolesPermissionsScreen> {
  String? _selectedRoleId;

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(organizationRolesProvider);

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Roles & Permissions',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'View the real roles and permissions for this organization.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: roles.when(
                data: (data) {
                  if (data.isEmpty) {
                    return const EmptyState(
                      icon: Icons.shield_outlined,
                      title: 'No roles yet.',
                      message: 'Roles configured for this organization will appear here.',
                    );
                  }

                  final selected = data.firstWhere(
                    (role) => role.id == _selectedRoleId,
                    orElse: () => data.first,
                  );

                  return _RolesBody(
                    roles: data,
                    selected: selected,
                    onSelect: (roleId) => setState(() => _selectedRoleId = roleId),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _RolesErrorState(
                  onRetry: () => ref.invalidate(organizationRolesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolesErrorState extends StatelessWidget {
  const _RolesErrorState({required this.onRetry});

  final VoidCallback onRetry;

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
            const Text(
              'Could not load roles.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _RolesBody extends StatelessWidget {
  const _RolesBody({required this.roles, required this.selected, required this.onSelect});

  final List<RoleSummary> roles;
  final RoleSummary selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text('Roles', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              for (var i = 0; i < roles.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _RoleTile(
                  role: roles[i],
                  isSelected: roles[i].id == selected.id,
                  onTap: () => onSelect(roles[i].id),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Permissions for ${selected.name}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        if (selected.permissions.isEmpty)
          const Text(
            'No permissions are assigned to this role yet.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < selected.permissions.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _PermissionRow(permission: selected.permissions[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.role, required this.isSelected, required this.onTap});

  final RoleSummary role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        child: const Icon(Icons.shield_outlined, color: AppColors.brandPrimary),
      ),
      title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      subtitle: (role.description != null && role.description!.isNotEmpty)
          ? Text(role.description!, style: const TextStyle(color: AppColors.textSecondary))
          : null,
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.brandPrimary) : null,
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.permission});

  final PermissionSummary permission;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.brandPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              permission.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
