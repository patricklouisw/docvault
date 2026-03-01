import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/constants/app_spacing.dart';

class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  static const _sections = [
    _Section('Onboarding', [
      _PageEntry('Splash', AppRoutes.splash, Icons.flash_on),
      _PageEntry(
        'Onboarding',
        AppRoutes.onboarding,
        Icons.swipe,
      ),
    ]),
    _Section('Auth', [
      _PageEntry(
        'Login or Sign Up',
        AppRoutes.loginOrSignup,
        Icons.login,
      ),
      _PageEntry(
        'Sign Up',
        AppRoutes.signUp,
        Icons.person_add,
      ),
      _PageEntry(
        'Sign Up (Social)',
        AppRoutes.signUp,
        Icons.people,
        extra: 2,
      ),
      _PageEntry(
        'Sign In',
        AppRoutes.signIn,
        Icons.lock_open,
      ),
      _PageEntry(
        'Forgot Password - Email',
        AppRoutes.forgotPasswordEmail,
        Icons.mail_outline,
      ),
      _PageEntry(
        'Forgot Password - OTP',
        AppRoutes.forgotPasswordOtp,
        Icons.pin,
      ),
      _PageEntry(
        'Forgot Password - New Password',
        AppRoutes.forgotPasswordNewPassword,
        Icons.lock_reset,
      ),
    ]),
    _Section('Vault', [
      _PageEntry(
        'Vault Unlock',
        AppRoutes.vaultUnlock,
        Icons.lock,
      ),
    ]),
    _Section('Home', [
      _PageEntry(
        'Documents',
        AppRoutes.documents,
        Icons.folder_outlined,
      ),
      _PageEntry(
        'Packages',
        AppRoutes.packages,
        Icons.inventory_2_outlined,
      ),
      _PageEntry(
        'Templates',
        AppRoutes.templates,
        Icons.description_outlined,
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.developer_mode,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Dev Menu'),
          ],
        ),
      ),
      body: ListView(
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
    );
  }
}

class _Section {
  const _Section(this.title, this.pages);
  final String title;
  final List<_PageEntry> pages;
}

class _PageEntry {
  const _PageEntry(this.label, this.route, this.icon,
      {this.extra});
  final String label;
  final String route;
  final IconData icon;
  final Object? extra;
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
        AppSpacing.lg,
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
      leading: Icon(
        entry.icon,
        color: colorScheme.primary,
      ),
      title: Text(entry.label),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () => context.go(entry.route, extra: entry.extra),
    );
  }
}
