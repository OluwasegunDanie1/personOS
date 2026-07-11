import 'package:flutter/material.dart';

void main() {
  runApp(const RelvioApp());
}

class RelvioApp extends StatelessWidget {
  const RelvioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: RelvioBootstrapScreen());
  }
}

class RelvioBootstrapScreen extends StatelessWidget {
  const RelvioBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Relvio')));
  }
}
