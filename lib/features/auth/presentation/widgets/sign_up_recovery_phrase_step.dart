import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:docvault/core/constants/app_spacing.dart';
import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/widgets/primary_button.dart';

class SignUpRecoveryPhraseStep extends StatelessWidget {
  const SignUpRecoveryPhraseStep({
    super.key,
    required this.hasSavedRecoveryPhrase,
    required this.onSavedChanged,
    required this.onContinue,
  });

  final bool hasSavedRecoveryPhrase;
  final ValueChanged<bool> onSavedChanged;
  final VoidCallback onContinue;

  // Placeholder phrase — will be replaced by crypto service
  static const _placeholderPhrase =
      'apple brave cherry delta echo '
      'flame grape house ivory jungle '
      'kite lemon';

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(
      const ClipboardData(text: _placeholderPhrase),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery phrase copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Key icon
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.key,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              AppStrings.yourRecoveryPhrase,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              AppStrings.recoveryPhraseSubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Phrase card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border:
                  Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _placeholderPhrase,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Copy button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyToClipboard(context),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text(AppStrings.copyToClipboard),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Warning card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppStrings.recoveryWarning,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Checkbox
          Row(
            children: [
              Checkbox(
                value: hasSavedRecoveryPhrase,
                onChanged: (value) =>
                    onSavedChanged(value ?? false),
              ),
              Expanded(
                child: Text(
                  AppStrings.iHaveSavedMyRecoveryPhrase,
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: AppStrings.continueText,
            onPressed:
                hasSavedRecoveryPhrase ? onContinue : null,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
