/// Widget tests for [PasswordField] — a TextFormField with a toggle
/// to show/hide the entered text.
///
/// Tests verify:
/// - Label renders
/// - Text is obscured by default (dots instead of characters)
/// - The visibility_off icon appears initially
/// - Tapping the icon toggles to visibility_on and unobscures text
/// - onChanged callback fires when the user types
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/widgets/password_field.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('PasswordField', () {
    /// The label is displayed above the input field.
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(testApp(
        const PasswordField(label: 'Password'),
      ));

      expect(find.text('Password'), findsOneWidget);
    });

    /// By default, the underlying EditableText should have
    /// obscureText = true so characters appear as dots.
    testWidgets('text is obscured by default', (tester) async {
      await tester.pumpWidget(testApp(
        const PasswordField(label: 'Password'),
      ));

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.obscureText, isTrue);
    });

    /// The closed-eye icon indicates text is currently hidden.
    testWidgets('shows visibility_off icon initially',
        (tester) async {
      await tester.pumpWidget(testApp(
        const PasswordField(label: 'Password'),
      ));

      expect(
        find.byIcon(Icons.visibility_off_outlined),
        findsOneWidget,
      );
    });

    /// After tapping the toggle icon, the open-eye icon should appear
    /// and the text should no longer be obscured.
    testWidgets('tapping icon toggles visibility', (tester) async {
      await tester.pumpWidget(testApp(
        const PasswordField(label: 'Password'),
      ));

      // Tap the visibility toggle icon.
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(
        find.byIcon(Icons.visibility_outlined),
        findsOneWidget,
      );

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.obscureText, isFalse);
    });

    /// The onChanged callback should receive the entered text.
    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;
      await tester.pumpWidget(testApp(
        PasswordField(
          label: 'Password',
          onChanged: (value) => changedValue = value,
        ),
      ));

      await tester.enterText(find.byType(TextFormField), 'secret');
      expect(changedValue, 'secret');
    });
  });
}
