/// Smoke tests for [DocVaultApp] — the root application widget.
///
/// These tests verify that the app boots without crashing and uses
/// the expected Material 3 theme. Because the production router
/// depends on Firebase (via auth state), we override
/// [appRouterProvider] with a minimal [GoRouter] that renders a
/// simple placeholder screen.
///
/// Tests verify:
/// - The app renders a [MaterialApp] and displays the test home screen
/// - The app's theme has Material 3 (`useMaterial3: true`) enabled
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/app.dart';
import 'package:docvault/app/router.dart';
import 'package:docvault/core/constants/app_strings.dart';

void main() {
  /// Verifies that [DocVaultApp] renders without throwing when the
  /// router is overridden to bypass Firebase dependencies.
  testWidgets('DocVaultApp renders without crashing', (tester) async {
    // Override router to avoid Firebase dependency.
    final testRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Test Home')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(testRouter),
        ],
        child: const DocVaultApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Test Home'), findsOneWidget);
  });

  /// Verifies that the app's theme uses Material 3, which is required
  /// by the project's design system (M3 color scheme, typography, etc.).
  testWidgets('DocVaultApp uses Material 3 theme', (tester) async {
    final testRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Center(child: Text(AppStrings.appName)),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(testRouter),
        ],
        child: const DocVaultApp(),
      ),
    );
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(materialApp.theme?.useMaterial3, isTrue);
  });
}
