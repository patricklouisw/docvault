import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/widgets/progress_bar.dart';
import 'package:docvault/features/auth/presentation/widgets/sign_up_profile_step.dart';
import 'package:docvault/features/auth/presentation/widgets/sign_up_account_step.dart';
import 'package:docvault/features/auth/presentation/widgets/sign_up_vault_setup_step.dart';
import 'package:docvault/features/auth/presentation/widgets/sign_up_recovery_phrase_step.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.initialStep = 0});

  final int initialStep;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late final PageController _pageController;
  late int _currentStep;

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  // Step 1 fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;

  // Step 2 fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _rememberMe = true;

  // Step 3 fields
  final _passphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();

  // Step 4 state
  bool _hasSavedRecoveryPhrase = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _pageController =
        PageController(initialPage: widget.initialStep);
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onStep1Continue() {
    if (_step1FormKey.currentState?.validate() ?? false) {
      _nextPage();
    }
  }

  void _onStep2Continue() {
    if (_step2FormKey.currentState?.validate() ?? false) {
      _nextPage();
    }
  }

  void _onStep3Continue() {
    if (_step3FormKey.currentState?.validate() ?? false) {
      _nextPage();
    }
  }

  void _onStep4Continue() {
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passphraseController.dispose();
    _confirmPassphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == widget.initialStep) {
              context.pop();
            } else {
              _previousPage();
            }
          },
        ),
        title: ProgressBar(
          currentStep: _currentStep + 1,
          totalSteps: 4,
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentStep = index);
        },
        children: [
          SignUpProfileStep(
            formKey: _step1FormKey,
            nameController: _nameController,
            phoneController: _phoneController,
            dobController: _dobController,
            selectedGender: _selectedGender,
            onGenderChanged: (value) {
              setState(() => _selectedGender = value);
            },
            onContinue: _onStep1Continue,
          ),
          SignUpAccountStep(
            formKey: _step2FormKey,
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController:
                _confirmPasswordController,
            rememberMe: _rememberMe,
            onRememberMeChanged: (value) {
              setState(() => _rememberMe = value);
            },
            onContinue: _onStep2Continue,
          ),
          SignUpVaultSetupStep(
            formKey: _step3FormKey,
            passphraseController: _passphraseController,
            confirmPassphraseController:
                _confirmPassphraseController,
            onContinue: _onStep3Continue,
          ),
          SignUpRecoveryPhraseStep(
            hasSavedRecoveryPhrase: _hasSavedRecoveryPhrase,
            onSavedChanged: (value) {
              setState(
                () => _hasSavedRecoveryPhrase = value,
              );
            },
            onContinue: _onStep4Continue,
          ),
        ],
      ),
    );
  }
}
