import 'package:docvault/core/constants/app_strings.dart';

class Validators {
  Validators._();

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final _phoneRegex = RegExp(r'^\+?[\d\s\-()]{7,15}$');

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.length < 8) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final error = Validators.password(value);
    if (error != null) return error;
    if (value != password) {
      return AppStrings.passwordsDoNotMatch;
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return AppStrings.invalidPhoneNumber;
    }
    return null;
  }

  static String? passphrase(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.length < 8) {
      return AppStrings.passphraseTooShort;
    }
    return null;
  }

  static String? confirmPassphrase(
    String? value,
    String passphrase,
  ) {
    final error = Validators.passphrase(value);
    if (error != null) return error;
    if (value != passphrase) {
      return AppStrings.passphrasesDoNotMatch;
    }
    return null;
  }
}
