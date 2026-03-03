/// Widget tests for [ForgotPasswordNewPasswordScreen] — the final step
/// of the forgot-password flow where the user creates a new password.
///
/// Tests verify:
/// - Title text ("Create New Password") renders
/// - Two [PasswordField] widgets are present (new password + confirm)
/// - Continue button is shown
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/widgets/password_field.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/features/auth/presentation/forgot_password_new_password_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ForgotPasswordNewPasswordScreen', () {
    /// The screen title should always be visible.
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(testApp(
        const ForgotPasswordNewPasswordScreen(),
      ));

      expect(
        find.textContaining(AppStrings.createNewPassword),
        findsOneWidget,
      );
    });

    /// Two password fields are required: one for the new password
    /// and one for confirming it matches.
    testWidgets('renders two password fields', (tester) async {
      await tester.pumpWidget(testApp(
        const ForgotPasswordNewPasswordScreen(),
      ));

      expect(find.byType(PasswordField), findsNWidgets(2));
    });

    /// The Continue button advances to the next step (or completes
    /// the password reset) after validation passes.
    testWidgets('renders Continue button', (tester) async {
      await tester.pumpWidget(testApp(
        const ForgotPasswordNewPasswordScreen(),
      ));

      expect(
        find.widgetWithText(
          PrimaryButton,
          AppStrings.continueText,
        ),
        findsOneWidget,
      );
    });
  });
}
