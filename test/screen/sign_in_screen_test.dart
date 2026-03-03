/// Screen tests for [SignInScreen] — the email/password sign-in form.
///
/// Requires [authRepositoryProvider] and [userRepositoryProvider]
/// overrides because the screen reads them for the sign-in action.
///
/// Tests verify the presence of key UI elements:
/// - Screen title
/// - Email input field (UnderlineTextField)
/// - Password input field (PasswordField)
/// - "Sign In" submit button (PrimaryButton)
/// - "Forgot Password?" link
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/widgets/password_field.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/core/widgets/underline_text_field.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';
import 'package:docvault/features/auth/presentation/sign_in_screen.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockUserRepository mockUserRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockUserRepo = MockUserRepository();
  });

  group('SignInScreen', () {
    /// The greeting title should be visible at the top of the screen.
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const SignInScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(
        find.textContaining(AppStrings.helloThere),
        findsOneWidget,
      );
    });

    /// An email input field should be present for the user's email.
    testWidgets('renders email field', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const SignInScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(find.byType(UnderlineTextField), findsOneWidget);
    });

    /// A password field with obscured text should be present.
    testWidgets('renders password field', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const SignInScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(find.byType(PasswordField), findsOneWidget);
    });

    /// The primary "Sign In" button should be available.
    testWidgets('renders Sign In button', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const SignInScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(
        find.widgetWithText(PrimaryButton, AppStrings.signIn),
        findsOneWidget,
      );
    });

    /// A "Forgot Password?" link should navigate to password reset.
    testWidgets('renders Forgot Password link', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const SignInScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(
        find.text(AppStrings.forgotPassword),
        findsOneWidget,
      );
    });
  });
}
