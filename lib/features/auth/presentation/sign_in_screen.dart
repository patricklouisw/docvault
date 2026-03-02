import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
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

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _onSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userRepo = ref.read(userRepositoryProvider);
      final uid = authRepo.currentUser!.uid;
      await userRepo.createUserIfNotExists(uid);

      if (!mounted) return;
      context.go(AppRoutes.vaultUnlock);
    } on FirebaseAuthException catch (e) {
      log('Sign in FirebaseAuth error: ${e.code}', name: 'SignInScreen');
      setState(() => _errorText = _mapAuthError(e.code));
    } catch (e, stackTrace) {
      log(
        'Sign in unexpected error: $e',
        name: 'SignInScreen',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() => _errorText = '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSocialSignIn(
    Future<UserCredential> Function() signInMethod,
  ) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await signInMethod();

      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final uid = authRepo.currentUser!.uid;
      await userRepo.createUserIfNotExists(uid);

      if (!mounted) return;
      context.go(AppRoutes.vaultUnlock);
    } on FirebaseAuthException catch (e) {
      log('Social sign in FirebaseAuth error: ${e.code}', name: 'SignInScreen');
      setState(() => _errorText = _mapAuthError(e.code));
    } catch (e, stackTrace) {
      log(
        'Social sign in unexpected error: $e',
        name: 'SignInScreen',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() => _errorText = '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'sign-in-cancelled':
        return 'Sign-in was cancelled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${AppStrings.helloThere} \u{1F44B}',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.signInSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              UnderlineTextField(
                label: AppStrings.email,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                label: AppStrings.password,
                controller: _passwordController,
                validator: Validators.password,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorText!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPasswordEmail),
                  child: Text(
                    AppStrings.forgotPassword,
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: AppStrings.signIn,
                onPressed: _isLoading ? null : _onSignIn,
                isLoading: _isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.dontHaveAccount, style: textTheme.bodyMedium),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => context.push(AppRoutes.signUp),
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
              const SizedBox(height: AppSpacing.lg),

              const SizedBox(height: AppSpacing.md),
              // "or continue with" divider
              Row(
                children: [
                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      AppStrings.orContinueWith,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Social icon row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialIconButton(
                    icon: Icons.g_mobiledata,
                    onTap: _isLoading
                        ? null
                        : () => _onSocialSignIn(authRepo.signInWithGoogle),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _SocialIconButton(
                    icon: Icons.apple,
                    onTap: _isLoading
                        ? null
                        : () => _onSocialSignIn(authRepo.signInWithApple),
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

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.onSurface),
      ),
    );
  }
}
