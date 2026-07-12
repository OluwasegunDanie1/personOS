import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/empty_state.dart';

/// Matches design/ui-reference's Events header composition ("Events" /
/// "Manage every event in your organization."). Events/Attendance
/// real-data integration is explicitly out of Task 029's scope, so the
/// body honestly states the feature is not yet available rather than
/// showing any fabricated event.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: const Text('Events', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: AppColors.textSecondary), onPressed: null),
          IconButton(icon: const Icon(Icons.filter_list, color: AppColors.textSecondary), onPressed: null),
        ],
      ),
      body: const EmptyState(
        icon: Icons.event_outlined,
        title: 'Events is not yet available',
        message: 'This section is coming in a future build.',
      ),
    );
  }
}
