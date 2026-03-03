/// Widget tests for [HomeShellScreen] — the bottom navigation shell
/// that hosts the four main tabs: Documents, Packages, Templates,
/// and Profile.
///
/// Because [HomeShellScreen] receives its child from a [ShellRoute],
/// the test builds a real [GoRouter] with a [ShellRoute] and four
/// child routes matching the production routing structure.
///
/// Tests verify:
/// - [NavigationBar] renders with exactly 4 [NavigationDestination]s
/// - All four tab labels match their [AppStrings] constants
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/features/home/presentation/home_shell_screen.dart';

void main() {
  group('HomeShellScreen', () {
    /// Builds a [MaterialApp.router] with a [GoRouter] that mirrors
    /// the production ShellRoute structure. Each tab route renders a
    /// simple placeholder [Text] widget.
    Widget buildScreen() {
      final router = GoRouter(
        initialLocation: '/home/documents',
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                HomeShellScreen(child: child),
            routes: [
              GoRoute(
                path: '/home/documents',
                builder: (_, _) =>
                    const Center(child: Text('Documents Tab')),
              ),
              GoRoute(
                path: '/home/packages',
                builder: (_, _) =>
                    const Center(child: Text('Packages Tab')),
              ),
              GoRoute(
                path: '/home/templates',
                builder: (_, _) =>
                    const Center(child: Text('Templates Tab')),
              ),
              GoRoute(
                path: '/home/profile',
                builder: (_, _) =>
                    const Center(child: Text('Profile Tab')),
              ),
            ],
          ),
        ],
      );

      return MaterialApp.router(routerConfig: router);
    }

    /// The bottom navigation bar should have exactly four tabs
    /// for the main sections of the app.
    testWidgets('renders NavigationBar with 4 destinations',
        (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        find.byType(NavigationDestination),
        findsNWidgets(4),
      );
    });

    /// Each tab should display its correct label string.
    testWidgets('renders correct tab labels', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text(AppStrings.documents), findsOneWidget);
      expect(find.text(AppStrings.packages), findsOneWidget);
      expect(find.text(AppStrings.templates), findsOneWidget);
      expect(find.text(AppStrings.profile), findsOneWidget);
    });
  });
}
