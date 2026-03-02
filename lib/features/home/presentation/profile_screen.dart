import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docvault/core/constants/app_spacing.dart';
import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              CircleAvatar(
                radius: 40,
                backgroundColor:
                    theme.colorScheme.primaryContainer,
                child: Text(
                  _initials(user?.displayName, user?.email),
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(
                    color:
                        theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (user?.displayName != null &&
                  user!.displayName!.isNotEmpty)
                Text(
                  user.displayName!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (user?.email != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xs,
                  ),
                  child: Text(
                    user!.email!,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _onLogOut(ref),
                  icon: Icon(
                    Icons.logout,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    AppStrings.logOut,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? displayName, String? email) {
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'
            .toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  Future<void> _onLogOut(WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (e, stackTrace) {
      log(
        'ProfileScreen: sign-out failed: $e',
        name: 'ProfileScreen',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
