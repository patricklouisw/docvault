/// Widget tests for the three placeholder screens used as tab content
/// before their respective features are implemented:
/// - [DocumentsPlaceholderScreen]
/// - [PackagesPlaceholderScreen]
/// - [TemplatesPlaceholderScreen]
///
/// Each placeholder simply renders its section name and a "Coming Soon"
/// label. These tests ensure the placeholder UI is correctly wired up
/// so the home shell tabs do not crash.
///
/// Tests verify:
/// - Each screen renders its section title (Documents / Packages / Templates)
/// - Each screen renders the "Coming Soon" text
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/features/home/presentation/documents_placeholder_screen.dart';
import 'package:docvault/features/home/presentation/packages_placeholder_screen.dart';
import 'package:docvault/features/home/presentation/templates_placeholder_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DocumentsPlaceholderScreen', () {
    /// Should display "Documents" and "Coming Soon" text.
    testWidgets('renders Documents and Coming Soon', (tester) async {
      await tester.pumpWidget(
        testApp(const DocumentsPlaceholderScreen()),
      );

      expect(find.text(AppStrings.documents), findsOneWidget);
      expect(find.text(AppStrings.comingSoon), findsOneWidget);
    });
  });

  group('PackagesPlaceholderScreen', () {
    /// Should display "Packages" and "Coming Soon" text.
    testWidgets('renders Packages and Coming Soon', (tester) async {
      await tester.pumpWidget(
        testApp(const PackagesPlaceholderScreen()),
      );

      expect(find.text(AppStrings.packages), findsOneWidget);
      expect(find.text(AppStrings.comingSoon), findsOneWidget);
    });
  });

  group('TemplatesPlaceholderScreen', () {
    /// Should display "Templates" and "Coming Soon" text.
    testWidgets('renders Templates and Coming Soon',
        (tester) async {
      await tester.pumpWidget(
        testApp(const TemplatesPlaceholderScreen()),
      );

      expect(find.text(AppStrings.templates), findsOneWidget);
      expect(find.text(AppStrings.comingSoon), findsOneWidget);
    });
  });
}
