import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color brandPrimary = Color(0xFF2563FF);
  static const Color backgroundPrimary = Color(0xFFFCFCFD);

  // Additions matching the approved design/ui-reference visual language
  // (headline navy, secondary slate text, card surfaces, subtle borders,
  // destructive red). brandPrimary/backgroundPrimary above are unchanged.
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFDC2626);
}
