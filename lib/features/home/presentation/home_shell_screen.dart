import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/constants/app_strings.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    AppRoutes.documents,
    AppRoutes.packages,
    AppRoutes.templates,
  ];

  int _currentIndex(BuildContext context) {
    final location =
        GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.go(_tabs[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: AppStrings.documents,
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: AppStrings.packages,
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: AppStrings.templates,
          ),
        ],
      ),
    );
  }
}
