import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'event_models.dart';

/// Renders the presentation-derived lifecycle label only (Product Task
/// 061/062 controller authority) — never a persisted status value. Colors
/// are a fixed four-state mapping (not category-keyed, since category has
/// no fixed taxonomy/color authority).
class EventLifecycleBadge extends StatelessWidget {
  const EventLifecycleBadge({super.key, required this.status});

  final EventLifecycleStatus status;

  String get _label {
    switch (status) {
      case EventLifecycleStatus.cancelled:
        return 'Cancelled';
      case EventLifecycleStatus.today:
        return 'Today';
      case EventLifecycleStatus.completed:
        return 'Completed';
      case EventLifecycleStatus.upcoming:
        return 'Upcoming';
    }
  }

  Color get _color {
    switch (status) {
      case EventLifecycleStatus.cancelled:
        return AppColors.danger;
      case EventLifecycleStatus.today:
        return const Color(0xFF16A34A);
      case EventLifecycleStatus.completed:
        return AppColors.textSecondary;
      case EventLifecycleStatus.upcoming:
        return const Color(0xFF2563FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(_label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
