/// Unit tests for [SignUpFormNotifier] — the state holder for the
/// multi-step sign-up form (profile + account fields).
///
/// The notifier exposes [updateStep1], [updateStep2], and [clear].
/// Tests verify:
/// - Initial state defaults (all fields empty / null)
/// - Step 1 (profile) and step 2 (account) each set their own fields
///   while preserving the other step's data
/// - [clear] resets the entire form to defaults
/// - Riverpod provider wiring via [ProviderContainer]
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/features/auth/domain/auth_provider.dart';

void main() {
  group('SignUpFormNotifier', () {
    late SignUpFormNotifier notifier;

    setUp(() {
      notifier = SignUpFormNotifier();
    });

    /// Freshly created notifier should have empty / null defaults.
    test('initial state has empty defaults', () {
      final state = notifier.state;
      expect(state.fullName, '');
      expect(state.phoneNumber, '');
      expect(state.gender, isNull);
      expect(state.dateOfBirth, isNull);
      expect(state.email, '');
      expect(state.password, '');
    });

    /// Calling updateStep1 should populate profile fields.
    test('updateStep1 sets profile fields', () {
      final dob = DateTime(1990, 5, 15);
      notifier.updateStep1(
        fullName: 'John Doe',
        phoneNumber: '+1234567890',
        gender: 'Male',
        dateOfBirth: dob,
      );

      final state = notifier.state;
      expect(state.fullName, 'John Doe');
      expect(state.phoneNumber, '+1234567890');
      expect(state.gender, 'Male');
      expect(state.dateOfBirth, dob);
    });

    /// Step 1 update must not overwrite previously entered step 2 data.
    test('updateStep1 preserves step 2 data', () {
      notifier.updateStep2(
        email: 'john@example.com',
        password: 'password123',
      );
      notifier.updateStep1(
        fullName: 'John Doe',
        phoneNumber: '+1234567890',
      );

      final state = notifier.state;
      expect(state.email, 'john@example.com');
      expect(state.password, 'password123');
    });

    /// Calling updateStep2 should populate account fields.
    test('updateStep2 sets account fields', () {
      notifier.updateStep2(
        email: 'john@example.com',
        password: 'password123',
      );

      final state = notifier.state;
      expect(state.email, 'john@example.com');
      expect(state.password, 'password123');
    });

    /// Step 2 update must not overwrite previously entered step 1 data.
    test('updateStep2 preserves step 1 data', () {
      notifier.updateStep1(
        fullName: 'John Doe',
        phoneNumber: '+1234567890',
      );
      notifier.updateStep2(
        email: 'john@example.com',
        password: 'password123',
      );

      final state = notifier.state;
      expect(state.fullName, 'John Doe');
      expect(state.phoneNumber, '+1234567890');
    });

    /// After calling clear, all fields should revert to their defaults.
    test('clear resets all fields', () {
      notifier.updateStep1(
        fullName: 'John Doe',
        phoneNumber: '+1234567890',
        gender: 'Male',
        dateOfBirth: DateTime(1990, 5, 15),
      );
      notifier.updateStep2(
        email: 'john@example.com',
        password: 'password123',
      );
      notifier.clear();

      final state = notifier.state;
      expect(state.fullName, '');
      expect(state.email, '');
      expect(state.gender, isNull);
      expect(state.dateOfBirth, isNull);
    });

    /// Verify that [signUpFormProvider] is correctly wired and
    /// state updates propagate through the Riverpod container.
    test('provider wiring works via ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final form = container.read(signUpFormProvider);
      expect(form.fullName, '');

      container.read(signUpFormProvider.notifier).updateStep1(
            fullName: 'Jane',
            phoneNumber: '123',
          );

      final updated = container.read(signUpFormProvider);
      expect(updated.fullName, 'Jane');
    });
  });
}
