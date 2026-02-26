import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/app/theme.dart';
import 'package:docvault/core/constants/app_strings.dart';

class DocVaultApp extends ConsumerWidget {
  const DocVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
