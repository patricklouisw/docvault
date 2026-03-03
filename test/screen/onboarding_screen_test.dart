/// Screen tests for [OnboardingScreen] — the swipeable onboarding
/// pages shown to first-time users before sign-up.
///
/// Tests verify key UI elements on the initial (first page) render:
/// - "Skip" button to bypass onboarding
/// - First page title text
/// - "Next" button to advance to the next page
/// - Underlying PageView widget exists for swiping
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/features/onboarding/presentation/onboarding_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('OnboardingScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    /// Users should be able to skip onboarding entirely.
    testWidgets('renders Skip button', (tester) async {
      await tester.pumpWidget(testApp(
        const OnboardingScreen(),
      ));

      expect(
        find.text(AppStrings.onboardingSkip),
        findsOneWidget,
      );
    });

    /// The first onboarding page's headline should be visible.
    testWidgets('renders first page title', (tester) async {
      await tester.pumpWidget(testApp(
        const OnboardingScreen(),
      ));

      expect(
        find.text(AppStrings.onboardingTitle1),
        findsOneWidget,
      );
    });

    /// The "Next" button advances the user to the second page.
    testWidgets('renders Next button on first page', (tester) async {
      await tester.pumpWidget(testApp(
        const OnboardingScreen(),
      ));

      expect(
        find.widgetWithText(FilledButton, AppStrings.onboardingNext),
        findsOneWidget,
      );
    });

    /// The screen uses a PageView for swipeable page navigation.
    testWidgets('renders PageView', (tester) async {
      await tester.pumpWidget(testApp(
        const OnboardingScreen(),
      ));

      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
