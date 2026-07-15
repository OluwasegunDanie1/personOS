import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/empty_state.dart';
import '../../app/widgets/relvio_back_button.dart';
import '../organizations/organization_models.dart';
import 'organization_members_provider.dart';

/// No direct "Organization Members" list screen exists anywhere in
/// design/ui-reference (Product Task 049's reconciliation: 12.png's "More"
/// menu and Roles & Permissions screen only show a "Total Users" count, not
/// a list composition). Per the established Edit Person precedent (Product
/// Task 047), this screen therefore uses the accepted native Relvio list
/// language already established by People Directory's row composition
/// (avatar-initials circle, name, contact line, trailing badge) rather than
/// inventing a new visual system. Read-only: no invite, remove, or
/// role-change control exists anywhere on this screen, matching the real
/// GET .../members contract exactly (Product Task 050).
class OrganizationMembersScreen extends ConsumerWidget {
  const OrganizationMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(organizationMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: const RelvioBackButton(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Organization Members',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'View everyone with access to this organization.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: members.when(
                data: (data) => _MembersBody(members: data),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _MembersErrorState(
                  onRetry: () => ref.invalidate(organizationMembersProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersErrorState extends StatelessWidget {
  const _MembersErrorState({required this.onRetry});

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
              'Could not load organization members.',
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

class _MembersBody extends StatelessWidget {
  const _MembersBody({required this.members});

  final List<OrganizationMemberSummary> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_outlined,
        title: 'No members yet.',
        message: 'People with access to this organization will appear here.',
      );
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) => _MemberRow(member: members[index]),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final OrganizationMemberSummary member;

  @override
  Widget build(BuildContext context) {
    final user = member.user;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSubtle))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MemberAvatar(user: user),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    _RoleBadge(name: member.role.name),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mail_outline, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        user.email,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.25)),
      ),
      child: Text(
        name,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.user});

  final OrganizationMemberUser user;

  static const double _diameter = 44;

  @override
  Widget build(BuildContext context) {
    final initials = user.initials;
    if (initials.isNotEmpty) {
      return CircleAvatar(
        radius: _diameter / 2,
        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        child: Text(
          initials,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
        ),
      );
    }

    return CircleAvatar(
      radius: _diameter / 2,
      backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
      child: const Icon(Icons.person_outline, size: 20, color: AppColors.brandPrimary),
    );
  }
}
