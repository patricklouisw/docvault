/// Widget tests for [ForgotPasswordOtpScreen] — the OTP verification
/// step in the forgot-password flow where the user enters a code sent
/// to their email.
///
/// Tests verify:
/// - Title text ("You've Got Mail") renders
/// - Pinput OTP input widget is present
/// - Confirm button is shown
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/features/auth/presentation/forgot_password_otp_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ForgotPasswordOtpScreen', () {
    /// The screen title should always be visible.
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(testApp(
        const ForgotPasswordOtpScreen(),
      ));

      expect(
        find.textContaining(AppStrings.youveGotMail),
        findsOneWidget,
      );
    });

    /// The Pinput widget provides a multi-digit OTP input field
    /// where the user enters the verification code from their email.
    testWidgets('renders Pinput widget', (tester) async {
      await tester.pumpWidget(testApp(
        const ForgotPasswordOtpScreen(),
      ));

      expect(find.byType(Pinput), findsOneWidget);
    });

    /// The Confirm button submits the OTP for verification.
    testWidgets('renders Confirm button', (tester) async {
      await tester.pumpWidget(testApp(
        const ForgotPasswordOtpScreen(),
      ));

      expect(
        find.widgetWithText(PrimaryButton, AppStrings.confirm),
        findsOneWidget,
      );
    });
  });
}
