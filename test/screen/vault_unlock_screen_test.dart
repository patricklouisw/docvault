/// Widget tests for [VaultUnlockScreen] — the screen where returning
/// users unlock their vault by entering a passphrase (or switching to
/// a recovery phrase).
///
/// Provider overrides:
/// - [authRepositoryProvider] → [MockAuthRepository] with a fake user
/// - [vaultRepositoryProvider] → [MockVaultRepository]
///
/// Tests verify:
/// - Title ("Unlock Your Vault") renders
/// - Subtitle renders
/// - Unlock button is shown as a [PrimaryButton]
/// - Recovery phrase toggle link is visible
/// - Lock icon is displayed
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';
import 'package:docvault/features/vault/domain/vault_provider.dart';
import 'package:docvault/features/vault/presentation/vault_unlock_screen.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockVaultRepository mockVaultRepo;
  late MockUser mockUser;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockVaultRepo = MockVaultRepository();
    mockUser = MockUser();
    when(() => mockAuthRepo.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test-uid');
  });

  group('VaultUnlockScreen', () {
    Widget buildScreen() {
      return testAppWithProviders(
        const VaultUnlockScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          vaultRepositoryProvider.overrideWithValue(mockVaultRepo),
        ],
      );
    }

    /// The screen title should always be visible.
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(
        find.text(AppStrings.unlockYourVault),
        findsOneWidget,
      );
    });

    /// A subtitle provides additional context below the title.
    testWidgets('renders subtitle', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(
        find.text(AppStrings.unlockSubtitle),
        findsOneWidget,
      );
    });

    /// The primary action button should display "Unlock".
    testWidgets('renders Unlock button', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(
        find.widgetWithText(PrimaryButton, AppStrings.unlock),
        findsOneWidget,
      );
    });

    /// Users should be able to switch to recovery phrase entry
    /// via a toggle link below the passphrase field.
    testWidgets('renders recovery phrase toggle link',
        (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(
        find.text(AppStrings.useRecoveryPhraseInstead),
        findsOneWidget,
      );
    });

    /// A lock icon reinforces the vault security context.
    testWidgets('renders lock icon', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });
  });
}
