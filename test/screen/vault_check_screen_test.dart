/// Widget tests for [VaultCheckScreen] — the intermediate screen
/// shown while the app checks whether the current user has already
/// set up their vault (crypto metadata exists in Firestore).
///
/// The screen calls `_checkVaultStatus()` in `initState`, which is an
/// async operation that navigates on completion. To prevent navigation
/// errors in the test environment (no GoRouter in the tree), we mock
/// `hasVaultSetup()` with a [Completer] that never completes, keeping
/// the async function suspended indefinitely.
///
/// Tests verify:
/// - A [CircularProgressIndicator] loading spinner is displayed
/// - The screen is wrapped in a [Scaffold]
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:docvault/features/auth/domain/auth_provider.dart';
import 'package:docvault/features/vault/presentation/vault_check_screen.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockUserRepository mockUserRepo;
  late MockUser mockUser;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockUserRepo = MockUserRepository();
    mockUser = MockUser();
    when(() => mockAuthRepo.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test-uid');
    // Use a Completer that never completes so _checkVaultStatus
    // stays suspended and never tries to navigate.
    when(() => mockUserRepo.hasVaultSetup(any()))
        .thenAnswer((_) => Completer<bool>().future);
  });

  group('VaultCheckScreen', () {
    /// While vault status is being checked, a spinner should indicate
    /// that a background operation is in progress.
    testWidgets('renders loading spinner', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const VaultCheckScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );
    });

    /// The screen should be a standard Material [Scaffold].
    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(testAppWithProviders(
        const VaultCheckScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          userRepositoryProvider.overrideWithValue(mockUserRepo),
        ],
      ));

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
