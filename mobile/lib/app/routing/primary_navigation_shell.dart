import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Exact frozen five-item primary navigation order (Product Task 027):
/// Home, People, Events, Messages, Workspace. Do not add, remove, reorder,
/// or substitute any destination (no Dashboard/More/Settings/Attendance/
/// Follow-ups tab, no sixth item). Icon/label styling matches
/// design/ui-reference's bottom navigation bar (icon + always-visible
/// label, active item in brand blue).
class PrimaryNavigationShell extends StatelessWidget {
  const PrimaryNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _labels = ['Home', 'People', 'Events', 'Messages', 'Workspace'];
  static const _icons = [
    Icons.home_outlined,
    Icons.people_outline,
    Icons.calendar_today_outlined,
    Icons.chat_bubble_outline,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          child: NavigationBar(
            backgroundColor: AppColors.surfaceCard,
            indicatorColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              for (var i = 0; i < _labels.length; i++)
                NavigationDestination(
                  icon: Icon(_icons[i], color: AppColors.textSecondary),
                  selectedIcon: Icon(_icons[i], color: AppColors.brandPrimary),
                  label: _labels[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
