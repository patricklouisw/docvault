/// Widget tests for [ProfileScreen] — the user profile tab showing
/// the user's avatar (initials), display name, email, and a Log Out
/// button.
///
/// Provider overrides:
/// - [authRepositoryProvider] → [MockAuthRepository]
/// - [vaultRepositoryProvider] → [MockVaultRepository]
/// - [currentUserProvider] → a [MockUser] with displayName "John Doe"
///   and email "john@example.com"
///
/// Tests verify:
/// - "Profile" title appears in the app bar
/// - Log Out button is displayed
/// - User initials ("JD") are rendered inside a [CircleAvatar]
/// - User email is displayed
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';
import 'package:docvault/features/vault/domain/vault_provider.dart';
import 'package:docvault/features/home/presentation/profile_screen.dart';

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
    when(() => mockUser.displayName).thenReturn('John Doe');
    when(() => mockUser.email).thenReturn('john@example.com');
  });

  group('ProfileScreen', () {
    /// Builds the [ProfileScreen] with all required provider overrides.
    /// The [loggedIn] flag controls whether a mock user is provided
    /// to [currentUserProvider].
    Widget buildScreen({bool loggedIn = true}) {
      return testAppWithProviders(
        const ProfileScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          vaultRepositoryProvider.overrideWithValue(mockVaultRepo),
          currentUserProvider.overrideWithValue(
            loggedIn ? mockUser : null,
          ),
        ],
      );
    }

    /// The app bar should display "Profile".
    testWidgets('renders Profile in app bar', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text(AppStrings.profile), findsOneWidget);
    });

    /// A Log Out button must be accessible for the user to sign out.
    testWidgets('renders Log Out button', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text(AppStrings.logOut), findsOneWidget);
    });

    /// The user's initials (first letter of first + last name) should
    /// be displayed inside a [CircleAvatar]. "John Doe" → "JD".
    testWidgets('renders user initials in CircleAvatar',
        (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byType(CircleAvatar), findsOneWidget);
      // "John Doe" → "JD"
      expect(find.text('JD'), findsOneWidget);
    });

    /// The user's email address should be visible on the profile screen.
    testWidgets('renders user email', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('john@example.com'), findsOneWidget);
    });
  });
}
