import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/constants/app_spacing.dart';
import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/core/widgets/social_button.dart';

class LoginOrSignupScreen extends StatelessWidget {
  const LoginOrSignupScreen({super.key});

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
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              SocialButton(
                label: AppStrings.continueWithFacebook,
                icon: Icon(
                  Icons.facebook,
                  size: 24,
                  color: colorScheme.primary,
                ),
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              SocialButton(
                label: AppStrings.continueWithApple,
                icon: Icon(
                  Icons.apple,
                  size: 24,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {},
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
                onPressed: () =>
                    context.push(AppRoutes.signIn),
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
                    onTap: () =>
                        context.push(AppRoutes.signUpStep1),
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
