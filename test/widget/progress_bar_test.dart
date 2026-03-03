/// Widget tests for [ProgressBar] — the segmented progress indicator
/// displayed at the top of the multi-step sign-up flow.
///
/// Tests verify:
/// - Correct number of segments (Expanded widgets) based on totalSteps
/// - Active / inactive segment colors match the theme's colorScheme
///   at different step positions (1/4, 3/4, 4/4)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/widgets/progress_bar.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ProgressBar', () {
    /// A 4-step progress bar should render exactly 4 Expanded segments.
    testWidgets('renders correct number of segments', (tester) async {
      await tester.pumpWidget(testApp(
        const ProgressBar(currentStep: 1, totalSteps: 4),
      ));

      // Each step is an Expanded > Container.
      expect(find.byType(Expanded), findsNWidgets(4));
    });

    /// At step 1 of 4, only the first segment should use the
    /// primary color (active); the rest should be inactive.
    testWidgets('step 1 of 4 has 1 active segment', (tester) async {
      await tester.pumpWidget(testApp(
        const ProgressBar(currentStep: 1, totalSteps: 4),
      ));

      final colorScheme = Theme.of(
        tester.element(find.byType(ProgressBar)),
      ).colorScheme;

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ProgressBar),
          matching: find.byType(Container),
        ),
      );

      var activeCount = 0;
      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration?;
        if (decoration?.color == colorScheme.primary) {
          activeCount++;
        }
      }
      expect(activeCount, 1);
    });

    /// At step 3 of 4, three segments should be active.
    testWidgets('step 3 of 4 has 3 active segments',
        (tester) async {
      await tester.pumpWidget(testApp(
        const ProgressBar(currentStep: 3, totalSteps: 4),
      ));

      final colorScheme = Theme.of(
        tester.element(find.byType(ProgressBar)),
      ).colorScheme;

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ProgressBar),
          matching: find.byType(Container),
        ),
      );

      var activeCount = 0;
      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration?;
        if (decoration?.color == colorScheme.primary) {
          activeCount++;
        }
      }
      expect(activeCount, 3);
    });

    /// At step 4 of 4, all segments should be active.
    testWidgets('step 4 of 4 has all segments active',
        (tester) async {
      await tester.pumpWidget(testApp(
        const ProgressBar(currentStep: 4, totalSteps: 4),
      ));

      final colorScheme = Theme.of(
        tester.element(find.byType(ProgressBar)),
      ).colorScheme;

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ProgressBar),
          matching: find.byType(Container),
        ),
      );

      var activeCount = 0;
      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration?;
        if (decoration?.color == colorScheme.primary) {
          activeCount++;
        }
      }
      expect(activeCount, 4);
    });
  });
}
