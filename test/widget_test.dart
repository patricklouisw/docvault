import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docvault/app/app.dart';

void main() {
  testWidgets('DocVaultApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DocVaultApp()),
    );
    await tester.pump();

    expect(find.text('DocuVault'), findsOneWidget);
  });
}
