import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

class RelvioApp extends StatelessWidget {
  const RelvioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: const RelvioBootstrapScreen(),
    );
  }
}

class RelvioBootstrapScreen extends StatelessWidget {
  const RelvioBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Relvio')));
  }
}
