/// Screen tests for [ForgotPasswordEmailScreen] — the first step of
/// the password reset flow where the user enters their email address.
///
/// Requires [authRepositoryProvider] override because the screen
/// reads it for the password reset action.
///
/// Tests verify:
/// - Screen title
/// - Email input field (UnderlineTextField)
/// - Continue button (PrimaryButton)
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/core/widgets/underline_text_field.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';
import 'package:docvault/features/auth/presentation/forgot_password_email_screen.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  group('ForgotPasswordEmailScreen', () {
    /// The screen title should prompt the user to enter their email.
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const ForgotPasswordEmailScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
      ));

      expect(
        find.textContaining(AppStrings.forgotPasswordTitle),
        findsOneWidget,
      );
    });

    /// An email input field for the user's registered email.
    testWidgets('renders email field', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const ForgotPasswordEmailScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
      ));

      expect(find.byType(UnderlineTextField), findsOneWidget);
    });

    /// The Continue button sends the password reset email.
    testWidgets('renders Continue button', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const ForgotPasswordEmailScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
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
