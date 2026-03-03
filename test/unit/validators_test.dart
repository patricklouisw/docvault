/// Unit tests for [Validators] — form validation functions used across
/// sign-up, sign-in, vault unlock, and profile screens.
///
/// Each validator returns `null` on valid input and a user-facing error
/// string (from [AppStrings]) on invalid input. Tests cover:
/// - [Validators.required]: null / empty / whitespace rejection
/// - [Validators.email]: RFC-like format validation
/// - [Validators.password] / [Validators.confirmPassword]: min-length
///   and mismatch checks
/// - [Validators.phone]: digits-only with optional +, spaces, dashes
/// - [Validators.passphrase] / [Validators.confirmPassphrase]: vault
///   passphrase min-length and mismatch checks
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/constants/app_strings.dart';
import 'package:docvault/core/utils/validators.dart';

void main() {
  // -- required ---------------------------------------------------------------

  group('Validators.required', () {
    /// Valid non-empty input should pass (return null).
    test('returns null for non-empty string', () {
      expect(Validators.required('hello'), isNull);
    });

    /// Null input should trigger the "field required" error.
    test('returns error for null', () {
      expect(Validators.required(null), AppStrings.fieldRequired);
    });

    /// An empty string is treated the same as null.
    test('returns error for empty string', () {
      expect(Validators.required(''), AppStrings.fieldRequired);
    });

    /// Whitespace-only counts as empty after trimming.
    test('returns error for whitespace-only string', () {
      expect(Validators.required('   '), AppStrings.fieldRequired);
    });
  });

  // -- email ------------------------------------------------------------------

  group('Validators.email', () {
    /// Standard user@domain.tld format should pass.
    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    /// Emails with dots and plus-addressing should pass.
    test('returns null for email with dots and plus', () {
      expect(
        Validators.email('user.name+tag@domain.co.uk'),
        isNull,
      );
    });

    /// Null email triggers "field required" before format check.
    test('returns fieldRequired for null', () {
      expect(Validators.email(null), AppStrings.fieldRequired);
    });

    /// Empty email triggers "field required" before format check.
    test('returns fieldRequired for empty string', () {
      expect(Validators.email(''), AppStrings.fieldRequired);
    });

    /// Missing @ symbol is an invalid email format.
    test('returns invalidEmail for missing @', () {
      expect(
        Validators.email('userexample.com'),
        AppStrings.invalidEmail,
      );
    });

    /// Nothing after @ makes it invalid.
    test('returns invalidEmail for missing domain', () {
      expect(Validators.email('user@'), AppStrings.invalidEmail);
    });

    /// A domain without a TLD (no dot) is invalid.
    test('returns invalidEmail for missing TLD', () {
      expect(
        Validators.email('user@example'),
        AppStrings.invalidEmail,
      );
    });

    /// Spaces in the local part are not allowed.
    test('returns invalidEmail for spaces', () {
      expect(
        Validators.email('user @example.com'),
        AppStrings.invalidEmail,
      );
    });
  });

  // -- password ---------------------------------------------------------------

  group('Validators.password', () {
    /// Minimum 8 characters should pass.
    test('returns null for 8+ character password', () {
      expect(Validators.password('abcdefgh'), isNull);
    });

    /// Null triggers "field required".
    test('returns fieldRequired for null', () {
      expect(Validators.password(null), AppStrings.fieldRequired);
    });

    /// Empty triggers "field required".
    test('returns fieldRequired for empty string', () {
      expect(Validators.password(''), AppStrings.fieldRequired);
    });

    /// 7 characters is below the 8-character minimum.
    test('returns passwordTooShort for 7-character string', () {
      expect(
        Validators.password('abcdefg'),
        AppStrings.passwordTooShort,
      );
    });
  });

  // -- confirmPassword --------------------------------------------------------

  group('Validators.confirmPassword', () {
    /// Matching passwords of valid length should pass.
    test('returns null when passwords match', () {
      expect(
        Validators.confirmPassword('abcdefgh', 'abcdefgh'),
        isNull,
      );
    });

    /// Mismatched passwords produce a "do not match" error.
    test('returns passwordsDoNotMatch when different', () {
      expect(
        Validators.confirmPassword('abcdefgh', 'different'),
        AppStrings.passwordsDoNotMatch,
      );
    });

    /// Even if both match, too-short passwords fail length check first.
    test('returns passwordTooShort when confirm is too short', () {
      expect(
        Validators.confirmPassword('short', 'short'),
        AppStrings.passwordTooShort,
      );
    });
  });

  // -- phone ------------------------------------------------------------------

  group('Validators.phone', () {
    /// International format with leading + should pass.
    test('returns null for valid phone', () {
      expect(Validators.phone('+1234567890'), isNull);
    });

    /// Spaces and dashes are allowed as separators.
    test('returns null for phone with spaces and dashes', () {
      expect(Validators.phone('+1 234-567-8901'), isNull);
    });

    /// Null triggers "field required".
    test('returns fieldRequired for null', () {
      expect(Validators.phone(null), AppStrings.fieldRequired);
    });

    /// Alphabetic characters are not valid phone digits.
    test('returns invalidPhoneNumber for letters', () {
      expect(
        Validators.phone('abcdefg'),
        AppStrings.invalidPhoneNumber,
      );
    });
  });

  // -- passphrase -------------------------------------------------------------

  group('Validators.passphrase', () {
    /// Vault passphrase with 8+ characters should pass.
    test('returns null for 8+ char passphrase', () {
      expect(Validators.passphrase('my secret'), isNull);
    });

    /// Below 8 characters triggers "passphrase too short".
    test('returns passphraseTooShort for 7-char passphrase', () {
      expect(
        Validators.passphrase('short'),
        AppStrings.passphraseTooShort,
      );
    });

    /// Null triggers "field required".
    test('returns fieldRequired for null', () {
      expect(
        Validators.passphrase(null),
        AppStrings.fieldRequired,
      );
    });
  });

  // -- confirmPassphrase ------------------------------------------------------

  group('Validators.confirmPassphrase', () {
    /// Matching passphrases should pass.
    test('returns null when passphrases match', () {
      expect(
        Validators.confirmPassphrase('my secret', 'my secret'),
        isNull,
      );
    });

    /// Mismatched passphrases produce a "do not match" error.
    test('returns passphrasesDoNotMatch when different', () {
      expect(
        Validators.confirmPassphrase('my secret', 'other one'),
        AppStrings.passphrasesDoNotMatch,
      );
    });
  });
}
