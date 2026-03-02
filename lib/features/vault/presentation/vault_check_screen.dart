import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';

/// Thin screen that checks whether the user has completed
/// vault setup, then routes to unlock or setup accordingly.
class VaultCheckScreen extends ConsumerStatefulWidget {
  const VaultCheckScreen({super.key});

  @override
  ConsumerState<VaultCheckScreen> createState() =>
      _VaultCheckScreenState();
}

class _VaultCheckScreenState
    extends ConsumerState<VaultCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkVaultStatus();
  }

  Future<void> _checkVaultStatus() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final user = authRepo.currentUser;

      if (user == null) {
        if (!mounted) return;
        context.go(AppRoutes.loginOrSignup);
        return;
      }

      final hasVault =
          await userRepo.hasVaultSetup(user.uid);

      if (!mounted) return;

      if (hasVault) {
        log(
          'Vault exists — going to unlock',
          name: 'VaultCheckScreen',
        );
        context.go(AppRoutes.vaultUnlock);
      } else {
        log(
          'No vault — going to vault setup (sign-up step 2)',
          name: 'VaultCheckScreen',
        );
        context.go(AppRoutes.signUp, extra: 2);
      }
    } catch (e, stackTrace) {
      log(
        'Vault check error: $e',
        name: 'VaultCheckScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      context.go(AppRoutes.loginOrSignup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
