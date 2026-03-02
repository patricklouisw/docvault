import 'dart:developer';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/constants/app_spacing.dart';
import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/utils/validators.dart';
import 'package:docvault/core/widgets/password_field.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/core/widgets/underline_text_field.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';
import 'package:docvault/features/vault/domain/vault_provider.dart';

class VaultUnlockScreen extends ConsumerStatefulWidget {
  const VaultUnlockScreen({super.key});

  @override
  ConsumerState<VaultUnlockScreen> createState() =>
      _VaultUnlockScreenState();
}

class _VaultUnlockScreenState
    extends ConsumerState<VaultUnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passphraseController = TextEditingController();
  final _recoveryController = TextEditingController();
  bool _useRecovery = false;
  bool _isLoading = false;
  String? _errorText;

  Future<void> _onUnlock() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final uid =
          ref.read(authRepositoryProvider).currentUser!.uid;
      final vaultNotifier =
          ref.read(vaultProvider.notifier);

      if (_useRecovery) {
        await vaultNotifier.unlockWithRecovery(
          uid: uid,
          recoveryPhrase: _recoveryController.text.trim(),
        );
      } else {
        await vaultNotifier.unlockWithPassphrase(
          uid: uid,
          passphrase: _passphraseController.text,
        );
      }

      if (!mounted) return;

      if (_useRecovery) {
        // Recovery unlock → redirect to sign-up steps 3-4
        // so user creates a new passphrase + gets new recovery phrase.
        context.go(AppRoutes.signUp, extra: 2);
      } else {
        context.go(AppRoutes.home);
      }
    } on SecretBoxAuthenticationError {
      setState(
        () => _errorText = _useRecovery
            ? AppStrings.incorrectRecoveryPhrase
            : AppStrings.incorrectPassphrase,
      );
    } catch (e, stackTrace) {
      log(
        'Vault unlock error: $e',
        name: 'VaultUnlockScreen',
        error: e,
        stackTrace: stackTrace,
      );
      setState(
        () => _errorText = 'Unlock failed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                // Lock icon
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        colorScheme.primaryContainer,
                    child: Icon(
                      Icons.lock_outlined,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    AppStrings.unlockYourVault,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    AppStrings.unlockSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Input field
                if (_useRecovery)
                  UnderlineTextField(
                    label:
                        AppStrings.useRecoveryPhraseInstead,
                    controller: _recoveryController,
                    validator: Validators.required,
                  )
                else
                  PasswordField(
                    label: AppStrings.enterPassphrase,
                    controller: _passphraseController,
                    validator: Validators.passphrase,
                  ),
                // Error text
                if (_errorText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorText!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // Toggle link
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _useRecovery = !_useRecovery;
                              _errorText = null;
                            });
                          },
                    child: Text(
                      _useRecovery
                          ? AppStrings.enterPassphrase
                          : AppStrings
                              .useRecoveryPhraseInstead,
                      style: TextStyle(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: AppStrings.unlock,
                  onPressed: _isLoading ? null : _onUnlock,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
