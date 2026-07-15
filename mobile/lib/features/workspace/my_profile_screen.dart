import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/relvio_back_button.dart';
import '../auth/auth_models.dart';
import '../auth/auth_session_controller.dart';

const _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${_monthAbbreviations[local.month - 1]} ${local.day}, ${local.year}';
}

/// Matches design/ui-reference/12.png's "My Profile" identity block only
/// (Product Task 080). The frozen screen also shows Edit Profile, Change
/// Password, Personal/Contact Information edit sections, Notification
/// Preferences, Connected Devices/Active Sessions, and Recent Activity
/// (Last Login/IP Address) — none of those has approved backend authority:
/// there is no PATCH /users/me, no authenticated change-password endpoint,
/// no notification-preferences model, and no session-list/revoke contract
/// (Product Task 071/079). This screen therefore renders only the real
/// PublicUser fields already held by AuthSessionController from the login
/// response — first/last name, email, phone (when present), status, member
/// since (createdAt), and last login (when present) — with no edit action
/// and no fabricated values for anything absent.
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionControllerProvider).user;

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
              child: const Text(
                'My Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: user == null ? const SizedBox.shrink() : _ProfileBody(user: user)),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    final initials = '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
        .toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${user.firstName} ${user.lastName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              _StatusBadge(status: user.status),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              _ProfileRow(icon: Icons.mail_outline, label: 'Email', value: user.email),
              if (user.phone != null && user.phone!.isNotEmpty) ...[
                const Divider(height: 1),
                _ProfileRow(icon: Icons.phone_outlined, label: 'Phone', value: user.phone!),
              ],
              const Divider(height: 1),
              _ProfileRow(icon: Icons.calendar_today_outlined, label: 'Member Since', value: _formatDate(user.createdAt)),
              if (user.lastLogin != null) ...[
                const Divider(height: 1),
                _ProfileRow(icon: Icons.login, label: 'Last Login', value: _formatDate(user.lastLogin!)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.25)),
      ),
      // Rendered exactly as returned by the backend — never relabelled.
      child: Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandPrimary)),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
