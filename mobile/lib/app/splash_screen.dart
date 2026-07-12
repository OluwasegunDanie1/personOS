import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'widgets/brand_mark.dart';

/// Matches design/ui-reference/splash.png: the Relvio mark and wordmark
/// centered on the brand background, with no visible spinner.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 120),
            SizedBox(height: 20),
            Text(
              'Relvio',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
