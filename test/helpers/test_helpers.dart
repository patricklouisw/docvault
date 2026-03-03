/// Shared test wrappers for widget and screen tests.
///
/// Provides convenience functions that wrap widgets in the necessary
/// [MaterialApp] / [ProviderScope] scaffolding so they can be pumped
/// in tests without manually building the widget tree each time.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docvault/app/theme.dart';

/// Wraps [child] in a themed [MaterialApp] for widget tests
/// that do NOT need Riverpod providers.
///
/// The child is placed inside a [Scaffold] body so that widgets
/// relying on a Scaffold ancestor (e.g. SnackBars) work correctly.
Widget testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

/// Wraps [child] in a [ProviderScope] + themed [MaterialApp]
/// for ConsumerWidget / ConsumerStatefulWidget tests.
///
/// Pass [overrides] to substitute mock providers (e.g.
/// `authRepositoryProvider.overrideWithValue(mockAuthRepo)`).
Widget testAppWithProviders(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}
