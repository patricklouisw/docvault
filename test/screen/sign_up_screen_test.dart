/// Screen tests for [SignUpScreen] — the multi-step registration form
/// (profile info, account credentials, vault passphrase, recovery phrase).
///
/// Requires auth, user, and vault repository provider overrides because
/// the screen uses all three during the sign-up flow.
///
/// Tests verify the first step's initial render:
/// - ProgressBar indicating current step
/// - "Complete Your Profile" step title
/// - Full Name input field
/// - Continue button to advance to the next step
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/widgets/progress_bar.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';
import 'package:docvault/features/auth/presentation/sign_up_screen.dart';
import 'package:docvault/features/vault/domain/vault_provider.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockUserRepository mockUserRepo;
  late MockVaultRepository mockVaultRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockUserRepo = MockUserRepository();
    mockVaultRepo = MockVaultRepository();
  });

  group('SignUpScreen', () {
    Widget buildScreen() {
      return testAppWithProviders(
        const SignUpScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
          vaultRepositoryProvider.overrideWithValue(mockVaultRepo),
        ],
      );
    }

    /// The ProgressBar shows which step the user is on (1 of 4).
    testWidgets('renders ProgressBar', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byType(ProgressBar), findsOneWidget);
    });

    /// The first step should display the "Complete Your Profile" title.
    testWidgets('renders first step title', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(
        find.textContaining(AppStrings.completeYourProfile),
        findsOneWidget,
      );
    });

    /// The Full Name field should be present on the first step.
    testWidgets('renders Full Name field on first step',
        (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text(AppStrings.fullName), findsOneWidget);
    });

    /// A Continue button advances to the next step after validation.
    testWidgets('renders Continue button', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(
        find.widgetWithText(
          ElevatedButton,
          AppStrings.continueText,
        ),
        findsOneWidget,
      );
    });
  });
}
