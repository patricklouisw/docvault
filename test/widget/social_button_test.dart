/// Widget tests for [SocialButton] — the outlined button used for
/// "Continue with Google" / "Continue with Apple" social sign-in options.
///
/// Tests verify:
/// - Label text renders
/// - Provider icon widget renders
/// - onPressed callback fires on tap
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/widgets/social_button.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SocialButton', () {
    /// The button label should be visible.
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(testApp(
        SocialButton(
          label: 'Continue with Google',
          icon: const Icon(Icons.g_mobiledata),
          onPressed: () {},
        ),
      ));

      expect(find.text('Continue with Google'), findsOneWidget);
    });

    /// The provider icon (e.g. Google "G") should be visible.
    testWidgets('renders icon widget', (tester) async {
      await tester.pumpWidget(testApp(
        SocialButton(
          label: 'Google',
          icon: const Icon(Icons.g_mobiledata),
          onPressed: () {},
        ),
      ));

      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
    });

    /// Tapping the button should invoke onPressed.
    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testApp(
        SocialButton(
          label: 'Google',
          icon: const Icon(Icons.g_mobiledata),
          onPressed: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Google'));
      expect(tapped, isTrue);
    });
  });
}
