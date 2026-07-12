import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centered icon-circle + headline + subtitle composition, matching
/// design/ui-reference's empty-state screens (e.g. People's "No people
/// yet."). Used here for scope stubs, so the copy states unavailability
/// honestly rather than implying a populated-but-empty data set.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: Color(0xFFEFF3FF), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: AppColors.brandPrimary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
