import 'package:flutter/material.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class RelvioApp extends StatelessWidget {
  const RelvioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(theme: AppTheme.light(), routerConfig: appRouter);
  }
}
