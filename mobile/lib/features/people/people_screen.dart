import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/empty_state.dart';

/// Matches design/ui-reference's People header composition ("People" /
/// "Manage everyone in your organization.", disabled search/filter
/// affordances). People real-data integration is explicitly out of Task
/// 029's scope, so the reference's populated list and "No people yet."
/// empty state (which implies a zero-record but wired-up backend) are not
/// used verbatim — the body instead honestly states the feature is not yet
/// available, with zero API calls and zero fabricated rows.
class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: const Text('People', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: AppColors.textSecondary), onPressed: null),
          IconButton(icon: const Icon(Icons.filter_list, color: AppColors.textSecondary), onPressed: null),
        ],
      ),
      body: const EmptyState(
        icon: Icons.groups_outlined,
        title: 'People is not yet available',
        message: 'This section is coming in a future build.',
      ),
    );
  }
}
