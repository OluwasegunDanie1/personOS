import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Matches the frozen back-affordance treatment used across pushed/form/
/// detail screens: a bordered rounded-square icon button, not a bare
/// Material [IconButton] (Product Task 088). Defaults to popping the current
/// route; pass [onPressed] to override (e.g. a Cancel action that also
/// clears controller state).
class RelvioBackButton extends StatelessWidget {
  const RelvioBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
