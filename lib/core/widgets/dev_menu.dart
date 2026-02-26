import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/constants/app_spacing.dart';

class DevMenu extends StatelessWidget {
  const DevMenu({super.key});

  static const _sections = [
    _Section('Onboarding', [
      _PageEntry('Splash', AppRoutes.splash),
      _PageEntry('Onboarding', AppRoutes.onboarding),
    ]),
    _Section('Auth', [
      _PageEntry('Login or Sign Up', AppRoutes.loginOrSignup),
      _PageEntry('Sign Up Step 1 (Profile)', AppRoutes.signUpStep1),
      _PageEntry('Sign Up Step 2 (Account)', AppRoutes.signUpStep2),
      _PageEntry('Sign In', AppRoutes.signIn),
      _PageEntry(
        'Forgot Password - Email',
        AppRoutes.forgotPasswordEmail,
      ),
      _PageEntry(
        'Forgot Password - OTP',
        AppRoutes.forgotPasswordOtp,
      ),
      _PageEntry(
        'Forgot Password - New Password',
        AppRoutes.forgotPasswordNewPassword,
      ),
    ]),
    _Section('Vault', [
      _PageEntry('Vault Setup', AppRoutes.vaultSetup),
      _PageEntry('Recovery Phrase', AppRoutes.recoveryPhrase),
      _PageEntry('Vault Unlock', AppRoutes.vaultUnlock),
    ]),
    _Section('Home', [
      _PageEntry('Documents', AppRoutes.documents),
      _PageEntry('Packages', AppRoutes.packages),
      _PageEntry('Templates', AppRoutes.templates),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.developer_mode,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Dev Menu',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: colorScheme.outlineVariant),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _sections
                    .expand(
                      (section) => [
                        _SectionHeader(title: section.title),
                        ...section.pages.map(
                          (page) => _PageTile(entry: page),
                        ),
                      ],
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section {
  const _Section(this.title, this.pages);
  final String title;
  final List<_PageEntry> pages;
}

class _PageEntry {
  const _PageEntry(this.label, this.route);
  final String label;
  final String route;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({required this.entry});
  final _PageEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      title: Text(entry.label),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        Navigator.of(context).pop(); // close drawer
        context.go(entry.route);
      },
    );
  }
}
