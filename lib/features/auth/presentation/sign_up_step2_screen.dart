import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/constants/app_spacing.dart';
import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/utils/validators.dart';
import 'package:docvault/core/widgets/password_field.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/core/widgets/progress_bar.dart';
import 'package:docvault/core/widgets/success_dialog.dart';
import 'package:docvault/core/widgets/underline_text_field.dart';

class SignUpStep2Screen extends StatefulWidget {
  const SignUpStep2Screen({super.key});

  @override
  State<SignUpStep2Screen> createState() =>
      _SignUpStep2ScreenState();
}

class _SignUpStep2ScreenState extends State<SignUpStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _rememberMe = true;

  void _onFinish() {
    if (_formKey.currentState?.validate() ?? false) {
      SuccessDialog.show(
        context,
        icon: Icons.person,
        title: AppStrings.signUpSuccessful,
        subtitle: AppStrings.accountCreated,
        buttonLabel: AppStrings.goToHome,
        onButtonPressed: () {
          Navigator.of(context).pop(); // close dialog
          context.go(AppRoutes.vaultSetup);
        },
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
        title: const ProgressBar(
          currentStep: 2,
          totalSteps: 2,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${AppStrings.createAnAccount} \u{1F510}',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.accountSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                label: AppStrings.confirmPassword,
                controller: _confirmPasswordController,
                validator: (value) =>
                    Validators.confirmPassword(
                  value,
                  _passwordController.text,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Remember me
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(
                        () => _rememberMe = value ?? false,
                      );
                    },
                  ),
                  Text(
                    AppStrings.rememberMe,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: AppStrings.finish,
                onPressed: _onFinish,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
