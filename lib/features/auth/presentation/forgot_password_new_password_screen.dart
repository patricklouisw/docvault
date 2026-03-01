import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/constants/app_spacing.dart';
import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/utils/validators.dart';
import 'package:docvault/core/widgets/password_field.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/core/widgets/success_dialog.dart';

class ForgotPasswordNewPasswordScreen extends StatefulWidget {
  const ForgotPasswordNewPasswordScreen({super.key});

  @override
  State<ForgotPasswordNewPasswordScreen> createState() =>
      _ForgotPasswordNewPasswordScreenState();
}

class _ForgotPasswordNewPasswordScreenState
    extends State<ForgotPasswordNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _rememberMe = true;

  void _onContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      SuccessDialog.show(
        context,
        icon: Icons.check_circle,
        title: AppStrings.resetPasswordSuccessful,
        buttonLabel: '',
        onButtonPressed: () {
          Navigator.of(context).pop();
          context.go(AppRoutes.loginOrSignup);
        },
        autoRedirectDelay: const Duration(milliseconds: 1000),
        onAutoRedirect: () {
          Navigator.of(context).pop();
          context.go(AppRoutes.loginOrSignup);
        },
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${AppStrings.createNewPassword} \u{1F510}',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.newPasswordSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PasswordField(
                label: AppStrings.password,
                controller: _passwordController,
                validator: Validators.password,
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                label: AppStrings.confirmPassword,
                controller: _confirmPasswordController,
                validator: (value) =>
                    Validators.confirmPassword(value, _passwordController.text),
              ),
              const SizedBox(height: AppSpacing.md),
              const Spacer(),
              PrimaryButton(
                label: AppStrings.continueText,
                onPressed: _onContinue,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
