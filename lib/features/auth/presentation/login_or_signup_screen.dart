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

class LoginOrSignupScreen extends ConsumerStatefulWidget {
  const LoginOrSignupScreen({super.key});

  @override
  ConsumerState<LoginOrSignupScreen> createState() =>
      _LoginOrSignupScreenState();
}

class _LoginOrSignupScreenState
    extends ConsumerState<LoginOrSignupScreen> {
  bool _isLoading = false;

  Future<void> _onSocialSignIn(
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
      context.go(AppRoutes.vaultUnlock);
    } on FirebaseAuthException catch (e) {
      log('Social sign in FirebaseAuth error: ${e.code}',
          name: 'LoginOrSignupScreen');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapAuthError(e.code))),
      );
    } catch (e, stackTrace) {
      log('Social sign in unexpected error: $e',
          name: 'LoginOrSignupScreen',
          error: e,
          stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'sign-in-cancelled':
        return 'Sign-in was cancelled.';
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
                  Icons.auto_awesome,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppStrings.letsYouIn,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Social buttons
              SocialButton(
                label: AppStrings.continueWithGoogle,
                icon: Icon(
                  Icons.g_mobiledata,
                  size: 28,
                  color: colorScheme.onSurface,
                ),
                onPressed: _isLoading
                    ? null
                    : () => _onSocialSignIn(
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
                    : () => _onSocialSignIn(
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
                label: AppStrings.signInWithPassword,
                onPressed: _isLoading
                    ? null
                    : () => context.push(AppRoutes.signIn),
              ),
              const SizedBox(height: AppSpacing.lg),
              // "Don't have an account? Sign up"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.dontHaveAccount,
                    style: textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => context
                            .push(AppRoutes.signUpMethod),
                    child: Text(
                      AppStrings.signUp,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
