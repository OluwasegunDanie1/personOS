import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RelvioBootstrapScreen(),
    ),
  ],
);

class RelvioBootstrapScreen extends StatelessWidget {
  const RelvioBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Relvio')));
  }
}
