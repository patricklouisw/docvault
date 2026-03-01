import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:docvault/core/constants/app_spacing.dart';
import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/utils/validators.dart';
import 'package:docvault/core/widgets/primary_button.dart';
import 'package:docvault/core/widgets/underline_text_field.dart';

class SignUpProfileStep extends StatelessWidget {
  const SignUpProfileStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.dobController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.onContinue,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController dobController;
  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onContinue;

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

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      dobController.text = DateFormat('MM/dd/yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
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
                    controller: nameController,
                    validator: Validators.required,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  UnderlineTextField(
                    label: AppStrings.phoneNumber,
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender,
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
                    onChanged: onGenderChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  UnderlineTextField(
                    label: AppStrings.dateOfBirth,
                    controller: dobController,
                    readOnly: true,
                    onTap: () => _pickDate(context),
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: PrimaryButton(
              label: AppStrings.continueText,
              onPressed: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}
