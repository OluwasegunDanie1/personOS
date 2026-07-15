import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brandPrimary,
      surface: AppColors.backgroundPrimary,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      // Without this, Material3's default OutlinedButton border falls back
      // to colorScheme.outline (a neutral gray), not the brand blue the
      // frozen UI uses for every secondary button (Product Task 088).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          side: const BorderSide(color: AppColors.brandPrimary),
        ),
      ),
    );
  }
}
