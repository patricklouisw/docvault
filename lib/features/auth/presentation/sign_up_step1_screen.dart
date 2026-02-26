import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:docvault/app/router.dart';
import 'package:docvault/core/constants/app_spacing.dart';
import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/utils/validators.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/core/widgets/progress_bar.dart';
import 'package:docvault/core/widgets/underline_text_field.dart';

class SignUpStep1Screen extends StatefulWidget {
  const SignUpStep1Screen({super.key});

  @override
  State<SignUpStep1Screen> createState() =>
      _SignUpStep1ScreenState();
}

class _SignUpStep1ScreenState extends State<SignUpStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;

  static const _genderOptions = [
    AppStrings.genderMale,
    AppStrings.genderFemale,
    AppStrings.genderOther,
    AppStrings.genderPreferNotToSay,
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    await picker.pickImage(source: ImageSource.gallery);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  void _onContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      context.push(AppRoutes.signUpStep2);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
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
          currentStep: 1,
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
                '${AppStrings.completeYourProfile} \u{1F4CB}',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.profileSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: colorScheme.primary,
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              UnderlineTextField(
                label: AppStrings.fullName,
                controller: _nameController,
                validator: Validators.required,
              ),
              const SizedBox(height: AppSpacing.md),
              UnderlineTextField(
                label: AppStrings.phoneNumber,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: AppStrings.gender,
                ),
                items: _genderOptions
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(g),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              UnderlineTextField(
                label: AppStrings.dateOfBirth,
                controller: _dobController,
                readOnly: true,
                onTap: _pickDate,
                suffixIcon: Icon(
                  Icons.calendar_today,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: AppStrings.continueText,
                onPressed: _onContinue,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
