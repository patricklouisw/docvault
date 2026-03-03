/// Screen tests for [LoginOrSignupScreen] — the entry point where
/// users choose between social sign-in (Google / Apple) or email.
///
/// Requires [authRepositoryProvider] and [userRepositoryProvider]
/// overrides because the screen reads them for social sign-in handlers.
///
/// Tests verify the presence of key UI elements:
/// - Headline title
/// - Google and Apple social buttons
/// - "Continue with Email" button
/// - "or" divider between social and email options
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/widgets/social_button.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';
import 'package:docvault/features/auth/presentation/login_or_signup_screen.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockUserRepository mockUserRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockUserRepo = MockUserRepository();
  });

  group('LoginOrSignupScreen', () {
    /// The screen headline should invite the user to sign in.
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const LoginOrSignupScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(find.text(AppStrings.letsYouIn), findsOneWidget);
    });

    /// The "Continue with Google" social button should be present.
    testWidgets('renders Google social button', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const LoginOrSignupScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(
        find.widgetWithText(
          SocialButton,
          AppStrings.continueWithGoogle,
        ),
        findsOneWidget,
      );
    });

    /// The "Continue with Apple" social button should be present.
    testWidgets('renders Apple social button', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const LoginOrSignupScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(
        find.widgetWithText(
          SocialButton,
          AppStrings.continueWithApple,
        ),
        findsOneWidget,
      );
    });

    /// The email sign-in option should be available below the divider.
    testWidgets('renders Continue with Email button',
        (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const LoginOrSignupScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(
        find.text(AppStrings.continueWithEmail),
        findsOneWidget,
      );
    });

    /// An "or" divider separates social buttons from the email option.
    testWidgets('renders "or" divider', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const LoginOrSignupScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(find.text(AppStrings.or), findsOneWidget);
    });
  });
}
