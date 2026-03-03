/// Screen tests for [SplashScreen] — the initial loading screen shown
/// while the app checks auth state and onboarding status.
///
/// Note: SplashScreen schedules a 2-second [Future.delayed] in
/// [initState] that navigates to the next route. To avoid the
/// "Timer is still pending" error at teardown, each test unmounts the
/// widget tree (setting `mounted = false`) then pumps past the timer
/// so the callback exits early.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/features/splash/presentation/splash_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SplashScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    /// The app name ("DocuVault") should be prominently displayed.
    testWidgets('renders app name', (tester) async {
      await tester.pumpWidget(testApp(const SplashScreen()));

      expect(find.text(AppStrings.appName), findsOneWidget);

      // Teardown: unmount then advance past the 2 s timer.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    /// The tagline below the app name should be visible.
    testWidgets('renders tagline', (tester) async {
      await tester.pumpWidget(testApp(const SplashScreen()));

      expect(
        find.text(AppStrings.splashTagline),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    /// A loading spinner should indicate the app is initialising.
    testWidgets('renders loading indicator', (tester) async {
      await tester.pumpWidget(testApp(const SplashScreen()));

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
