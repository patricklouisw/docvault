import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/constants/app_spacing.dart';
import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/core/widgets/social_button.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';

class SignUpMethodScreen extends ConsumerStatefulWidget {
  const SignUpMethodScreen({super.key});

  @override
  ConsumerState<SignUpMethodScreen> createState() =>
      _SignUpMethodScreenState();
}

class _SignUpMethodScreenState
    extends ConsumerState<SignUpMethodScreen> {
  bool _isLoading = false;

  Future<void> _onSocialSignUp(
    Future<UserCredential> Function() signInMethod,
  ) async {
    setState(() => _isLoading = true);

    try {
      await signInMethod();

      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final uid = authRepo.currentUser!.uid;
      await userRepo.createUserIfNotExists(uid);

      if (!mounted) return;
      // Social sign-up skips profile + account steps,
      // go straight to vault setup (step index 2).
      context.push(AppRoutes.signUp, extra: 2);
    } on FirebaseAuthException catch (e) {
      log('Social sign up error: ${e.code}',
          name: 'SignUpMethodScreen');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapAuthError(e.code))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'sign-in-cancelled':
        return 'Sign-up was cancelled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authRepo = ref.read(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
          child: Column(
            children: [
              const Spacer(),
              // Illustration placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppStrings.signUpMethodTitle,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.signUpMethodSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Social sign-up buttons
              SocialButton(
                label: AppStrings.continueWithGoogle,
                icon: Icon(
                  Icons.g_mobiledata,
                  size: 28,
                  color: colorScheme.onSurface,
                ),
                onPressed: _isLoading
                    ? null
                    : () => _onSocialSignUp(
                          authRepo.signInWithGoogle,
                        ),
              ),
              const SizedBox(height: AppSpacing.md),
              SocialButton(
                label: AppStrings.continueWithApple,
                icon: Icon(
                  Icons.apple,
                  size: 24,
                  color: colorScheme.onSurface,
                ),
                onPressed: _isLoading
                    ? null
                    : () => _onSocialSignUp(
                          authRepo.signInWithApple,
                        ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // "or" divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      AppStrings.or,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: AppStrings.signUpWithEmail,
                onPressed: _isLoading
                    ? null
                    : () => context.push(AppRoutes.signUp),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
