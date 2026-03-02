import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/widgets/progress_bar.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';
import 'package:docvault/features/auth/presentation/widgets/sign_up_profile_step.dart';
import 'package:docvault/features/auth/presentation/widgets/sign_up_account_step.dart';
import 'package:docvault/features/auth/presentation/widgets/sign_up_vault_setup_step.dart';
import 'package:docvault/features/auth/presentation/widgets/sign_up_recovery_phrase_step.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.initialStep = 0});

  final int initialStep;

  @override
  ConsumerState<SignUpScreen> createState() =>
      _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
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
  // Step 3 fields
  final _passphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();

  // Step 4 state
  bool _hasSavedRecoveryPhrase = false;

  bool _isLoading = false;
  String? _errorText;

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

  Future<void> _onStep2Continue() async {
    if (!(_step2FormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      _nextPage();
    } on FirebaseAuthException catch (e) {
      log('Sign up error: ${e.code}', name: 'SignUpScreen');
      setState(() => _errorText = _mapAuthError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onStep3Continue() {
    if (_step3FormKey.currentState?.validate() ?? false) {
      _nextPage();
    }
  }

  Future<void> _onStep4Continue() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final uid = authRepo.currentUser!.uid;
      await userRepo.createUserIfNotExists(uid);

      if (!mounted) return;
      context.go(AppRoutes.home);
    } on Exception catch (e) {
      log('User doc creation error: $e',
          name: 'SignUpScreen');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Something went wrong. Please try again.';
    }
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
          currentStep:
              _currentStep - widget.initialStep + 1,
          totalSteps: widget.initialStep == 0 ? 4 : 2,
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
            onContinue: _onStep2Continue,
            isLoading: _isLoading,
            errorText: _errorText,
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
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
