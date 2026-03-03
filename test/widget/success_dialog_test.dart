/// Widget tests for [SuccessDialog] — the full-screen success
/// confirmation shown after vault setup, password reset, etc.
///
/// Tests verify:
/// - Title text renders
/// - Optional subtitle renders when provided
/// - Action button is shown when there is no autoRedirectDelay
/// - Action button is hidden when autoRedirectDelay is set
///   (the dialog auto-navigates instead)
/// - onButtonPressed callback fires on button tap
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/widgets/success_dialog.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SuccessDialog', () {
    /// The title should always be visible.
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(testApp(
        SuccessDialog(
          icon: Icons.check,
          title: 'Success!',
          buttonLabel: 'OK',
          onButtonPressed: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Success!'), findsOneWidget);
    });

    /// When a subtitle is provided, it should appear below the title.
    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(testApp(
        SuccessDialog(
          icon: Icons.check,
          title: 'Done',
          subtitle: 'Your action was successful.',
          buttonLabel: 'OK',
          onButtonPressed: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('Your action was successful.'),
        findsOneWidget,
      );
    });

    /// Without auto-redirect, the manual button should be visible.
    testWidgets('renders button when no autoRedirectDelay',
        (tester) async {
      await tester.pumpWidget(testApp(
        SuccessDialog(
          icon: Icons.check,
          title: 'Done',
          buttonLabel: 'Go Home',
          onButtonPressed: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Go Home'), findsOneWidget);
    });

    /// When an auto-redirect delay is set, the button should be
    /// hidden because the dialog redirects automatically.
    testWidgets('hides button when autoRedirectDelay is set',
        (tester) async {
      await tester.pumpWidget(testApp(
        SuccessDialog(
          icon: Icons.check,
          title: 'Done',
          buttonLabel: 'Go Home',
          onButtonPressed: () {},
          autoRedirectDelay: const Duration(seconds: 2),
          onAutoRedirect: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Go Home'), findsNothing);
    });

    /// Tapping the button should invoke onButtonPressed.
    testWidgets('calls onButtonPressed when button tapped',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(testApp(
        SuccessDialog(
          icon: Icons.check,
          title: 'Done',
          buttonLabel: 'OK',
          onButtonPressed: () => pressed = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      expect(pressed, isTrue);
    });
  });
}
