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
    AppRoutes.profile,
  ];

  static const _tabLabels = [
    AppStrings.documents,
    AppStrings.packages,
    AppStrings.templates,
    AppStrings.profile,
  ];

  static const _tabIcons = [
    Icons.folder_outlined,
    Icons.inventory_2_outlined,
    Icons.description_outlined,
    Icons.person_outline,
  ];

  static const _tabSelectedIcons = [
    Icons.folder,
    Icons.inventory_2,
    Icons.description,
    Icons.person,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabLabels[currentIndex]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: NavigationDrawer(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          context.go(_tabs[index]);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
            child: Text(
              AppStrings.appName,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(indent: 28, endIndent: 28),
          for (var i = 0; i < _tabs.length; i++)
            NavigationDrawerDestination(
              icon: Icon(_tabIcons[i]),
              selectedIcon: Icon(_tabSelectedIcons[i]),
              label: Text(_tabLabels[i]),
            ),
        ],
      ),
      body: child,
    );
  }
}
