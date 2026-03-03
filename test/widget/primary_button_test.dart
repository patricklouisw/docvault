/// Widget tests for [PrimaryButton] — the main CTA button used on
/// sign-in, sign-up, vault unlock, and other action screens.
///
/// Tests verify:
/// - Label text renders correctly
/// - onPressed callback fires on tap
/// - Loading state shows a spinner instead of the label
/// - The button is disabled (non-tappable) while loading
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/widgets/primary_button.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('PrimaryButton', () {
    /// The label passed to PrimaryButton should appear as visible text.
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(testApp(
        PrimaryButton(label: 'Continue', onPressed: () {}),
      ));

      expect(find.text('Continue'), findsOneWidget);
    });

    /// Tapping the button should invoke the onPressed callback.
    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testApp(
        PrimaryButton(
          label: 'Tap Me',
          onPressed: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    /// When isLoading is true, a CircularProgressIndicator should be
    /// shown in place of the label text.
    testWidgets('shows CircularProgressIndicator when loading',
        (tester) async {
      await tester.pumpWidget(testApp(
        PrimaryButton(
          label: 'Loading',
          onPressed: () {},
          isLoading: true,
        ),
      ));

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );
    });

    /// The label text should be hidden while the spinner is visible.
    testWidgets('hides label text when loading', (tester) async {
      await tester.pumpWidget(testApp(
        PrimaryButton(
          label: 'Hidden',
          onPressed: () {},
          isLoading: true,
        ),
      ));

      expect(find.text('Hidden'), findsNothing);
    });

    /// A loading button must not trigger onPressed when tapped,
    /// preventing duplicate submissions.
    testWidgets('button is disabled when loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testApp(
        PrimaryButton(
          label: 'Disabled',
          onPressed: () => tapped = true,
          isLoading: true,
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isFalse);
    });
  });
}
