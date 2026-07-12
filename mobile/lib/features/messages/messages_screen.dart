import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/empty_state.dart';

/// Messages is a frozen primary-navigation destination (Product Task 027)
/// whose backend remains deferred/unresolved. Matches design/ui-reference's
/// Messages header ("Messages" / "Stay connected with your people.") with
/// search/compose disabled; the reference's populated inbox and category
/// tabs (All/Unread/Groups/Announcements) are not reproduced since they
/// imply real conversation data and a category model that do not exist —
/// this screen makes zero API calls and renders zero fake conversations.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Messages', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
            Text(
              'Stay connected with your people.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: AppColors.textSecondary), onPressed: null),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            onPressed: null,
            tooltip: 'Compose is not yet available',
          ),
        ],
      ),
      body: const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Messages is not yet available',
        message: 'This section is coming in a future build.',
      ),
    );
  }
}
