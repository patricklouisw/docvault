import 'package:flutter/material.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const Placeholder(
        fallbackHeight: 80,
      ),
    );
  }
}
