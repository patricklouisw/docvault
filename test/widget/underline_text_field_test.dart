/// Widget tests for [UnderlineTextField] — a styled TextFormField with
/// an underline border, used for email, phone, and read-only date fields.
///
/// Tests verify:
/// - Label renders
/// - onChanged callback fires when the user types
/// - suffixIcon is displayed when provided (e.g. calendar icon)
/// - onTap callback fires when a readOnly field is tapped
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/widgets/underline_text_field.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('UnderlineTextField', () {
    /// The label passed to the widget should be visible.
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(testApp(
        const UnderlineTextField(label: 'Email'),
      ));

      expect(find.text('Email'), findsOneWidget);
    });

    /// Typing into the field should invoke onChanged with the new text.
    testWidgets('calls onChanged when text entered', (tester) async {
      String? changedValue;
      await tester.pumpWidget(testApp(
        UnderlineTextField(
          label: 'Email',
          onChanged: (value) => changedValue = value,
        ),
      ));

      await tester.enterText(
        find.byType(TextFormField),
        'test@example.com',
      );
      expect(changedValue, 'test@example.com');
    });

    /// An optional suffix icon (e.g. calendar for date pickers) should
    /// render when provided.
    testWidgets('shows suffixIcon when provided', (tester) async {
      await tester.pumpWidget(testApp(
        const UnderlineTextField(
          label: 'Date',
          suffixIcon: Icon(Icons.calendar_today),
        ),
      ));

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    /// Read-only fields use onTap to open pickers (e.g. date picker).
    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testApp(
        UnderlineTextField(
          label: 'Date',
          readOnly: true,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(TextFormField));
      expect(tapped, isTrue);
    });
  });
}
