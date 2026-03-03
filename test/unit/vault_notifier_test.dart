/// Unit tests for [VaultNotifier] — the state machine that manages
/// the vault lifecycle (setup, unlock, lock, re-setup).
///
/// Uses [MockVaultRepository] (mocktail) so no real crypto or Firestore
/// calls are made. Tests verify state transitions through the sealed
/// [VaultState] hierarchy:
///
///   VaultLocked  ──setup()──>  VaultUnlocked
///   VaultLocked  ──unlock()──> VaultUnlocked
///   VaultUnlocked ──lock()──>  VaultLocked  (MK bytes zeroed)
///   Any state    ──setSetupRequired()──> VaultSetupRequired
///
/// Also tests error propagation (wrong passphrase) and the guard
/// on [reSetup] (must be unlocked).
library;

import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:docvault/features/vault/domain/vault_provider.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late MockVaultRepository mockRepo;
  late VaultNotifier notifier;

  /// 32-byte test master key filled with 0xAB.
  final testMK = Uint8List.fromList(List.filled(32, 0xAB));

  setUpAll(() {
    // Required for any(named: 'masterKey') matchers on Uint8List.
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockRepo = MockVaultRepository();
    notifier = VaultNotifier(vaultRepository: mockRepo);
  });

  // -- initial state ----------------------------------------------------------

  group('VaultNotifier', () {
    /// The notifier must start in VaultLocked until explicitly unlocked.
    test('initial state is VaultLocked', () {
      expect(notifier.state, isA<VaultLocked>());
    });
  });

  // -- setup ------------------------------------------------------------------

  group('setup', () {
    /// After a successful setup the vault should transition to
    /// VaultUnlocked and the repository should have been called once.
    test('calls setupVault and transitions to VaultUnlocked', () async {
      when(() => mockRepo.setupVault(
            uid: any(named: 'uid'),
            passphrase: any(named: 'passphrase'),
          )).thenAnswer((_) async => (
            masterKey: testMK,
            recoveryPhrase: 'word1 word2 word3',
          ));

      await notifier.setup(uid: 'uid1', passphrase: 'mypass');

      expect(notifier.state, isA<VaultUnlocked>());
      verify(() => mockRepo.setupVault(
            uid: 'uid1',
            passphrase: 'mypass',
          )).called(1);
    });

    /// The recovery phrase returned by the repo must be surfaced to
    /// the caller so it can be displayed to the user.
    test('returns the recovery phrase from repository', () async {
      when(() => mockRepo.setupVault(
            uid: any(named: 'uid'),
            passphrase: any(named: 'passphrase'),
          )).thenAnswer((_) async => (
            masterKey: testMK,
            recoveryPhrase: 'apple banana cherry',
          ));

      final phrase = await notifier.setup(
        uid: 'uid1',
        passphrase: 'mypass',
      );
      expect(phrase, 'apple banana cherry');
    });

    /// The master key must be accessible in the VaultUnlocked state
    /// so downstream code can derive file keys from it.
    test('stores masterKey in VaultUnlocked state', () async {
      when(() => mockRepo.setupVault(
            uid: any(named: 'uid'),
            passphrase: any(named: 'passphrase'),
          )).thenAnswer((_) async => (
            masterKey: testMK,
            recoveryPhrase: 'phrase',
          ));

      await notifier.setup(uid: 'uid1', passphrase: 'mypass');

      final state = notifier.state as VaultUnlocked;
      expect(state.masterKey, equals(testMK));
    });
  });

  // -- unlockWithPassphrase ---------------------------------------------------

  group('unlockWithPassphrase', () {
    /// Correct passphrase should transition to VaultUnlocked.
    test('transitions to VaultUnlocked on success', () async {
      when(() => mockRepo.unlockWithPassphrase(
            uid: any(named: 'uid'),
            passphrase: any(named: 'passphrase'),
          )).thenAnswer((_) async => testMK);

      await notifier.unlockWithPassphrase(
        uid: 'uid1',
        passphrase: 'mypass',
      );

      expect(notifier.state, isA<VaultUnlocked>());
    });

    /// Wrong passphrase causes a SecretBoxAuthenticationError from the
    /// crypto layer — the notifier must let it propagate and remain
    /// in VaultLocked.
    test('propagates SecretBoxAuthenticationError', () async {
      when(() => mockRepo.unlockWithPassphrase(
            uid: any(named: 'uid'),
            passphrase: any(named: 'passphrase'),
          )).thenThrow(SecretBoxAuthenticationError());

      expect(
        () => notifier.unlockWithPassphrase(
          uid: 'uid1',
          passphrase: 'wrong',
        ),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      expect(notifier.state, isA<VaultLocked>());
    });
  });

  // -- unlockWithRecovery -----------------------------------------------------

  group('unlockWithRecovery', () {
    /// Correct recovery phrase should transition to VaultUnlocked.
    test('transitions to VaultUnlocked on success', () async {
      when(() => mockRepo.unlockWithRecovery(
            uid: any(named: 'uid'),
            recoveryPhrase: any(named: 'recoveryPhrase'),
          )).thenAnswer((_) async => testMK);

      await notifier.unlockWithRecovery(
        uid: 'uid1',
        recoveryPhrase: 'word1 word2 word3',
      );

      expect(notifier.state, isA<VaultUnlocked>());
    });

    /// Wrong recovery phrase must propagate the auth error and keep
    /// the vault locked.
    test('propagates SecretBoxAuthenticationError', () async {
      when(() => mockRepo.unlockWithRecovery(
            uid: any(named: 'uid'),
            recoveryPhrase: any(named: 'recoveryPhrase'),
          )).thenThrow(SecretBoxAuthenticationError());

      expect(
        () => notifier.unlockWithRecovery(
          uid: 'uid1',
          recoveryPhrase: 'wrong phrase',
        ),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      expect(notifier.state, isA<VaultLocked>());
    });
  });

  // -- lock -------------------------------------------------------------------

  group('lock', () {
    /// Locking an unlocked vault should transition to VaultLocked.
    test('transitions from VaultUnlocked to VaultLocked', () async {
      when(() => mockRepo.unlockWithPassphrase(
            uid: any(named: 'uid'),
            passphrase: any(named: 'passphrase'),
          )).thenAnswer((_) async => testMK);

      await notifier.unlockWithPassphrase(
        uid: 'uid1',
        passphrase: 'pass',
      );
      expect(notifier.state, isA<VaultUnlocked>());

      notifier.lock();
      expect(notifier.state, isA<VaultLocked>());
    });

    /// The master key bytes must be zeroed on lock to minimise the
    /// window where sensitive material is in memory.
    test('zeros masterKey bytes before transitioning', () async {
      // Use a fresh MK so we can verify zeroing.
      final mk = Uint8List.fromList(List.filled(32, 0xFF));
      when(() => mockRepo.unlockWithPassphrase(
            uid: any(named: 'uid'),
            passphrase: any(named: 'passphrase'),
          )).thenAnswer((_) async => mk);

      await notifier.unlockWithPassphrase(
        uid: 'uid1',
        passphrase: 'pass',
      );

      notifier.lock();
      // All bytes should be zeroed.
      expect(mk.every((byte) => byte == 0), isTrue);
    });

    /// Locking an already-locked vault should be a safe no-op.
    test('no-op when already locked', () {
      expect(notifier.state, isA<VaultLocked>());
      notifier.lock();
      expect(notifier.state, isA<VaultLocked>());
    });
  });

  // -- setSetupRequired -------------------------------------------------------

  group('setSetupRequired', () {
    /// Used when a new user has no crypto metadata in Firestore.
    test('transitions to VaultSetupRequired', () {
      notifier.setSetupRequired();
      expect(notifier.state, isA<VaultSetupRequired>());
    });
  });

  // -- reSetup ----------------------------------------------------------------

  group('reSetup', () {
    /// Re-setup should call reSetupVault on the repo and return
    /// the new recovery phrase.
    test('calls reSetupVault when vault is unlocked', () async {
      // First unlock the vault.
      when(() => mockRepo.unlockWithPassphrase(
            uid: any(named: 'uid'),
            passphrase: any(named: 'passphrase'),
          )).thenAnswer((_) async => testMK);
      when(() => mockRepo.reSetupVault(
            uid: any(named: 'uid'),
            masterKey: any(named: 'masterKey'),
            newPassphrase: any(named: 'newPassphrase'),
          )).thenAnswer((_) async => 'new recovery phrase');

      await notifier.unlockWithPassphrase(
        uid: 'uid1',
        passphrase: 'pass',
      );

      final phrase = await notifier.reSetup(
        uid: 'uid1',
        newPassphrase: 'newpass',
      );

      expect(phrase, 'new recovery phrase');
      verify(() => mockRepo.reSetupVault(
            uid: 'uid1',
            masterKey: testMK,
            newPassphrase: 'newpass',
          )).called(1);
    });

    /// Re-setup requires the vault to be unlocked (MK in memory).
    /// Calling it while locked must throw a StateError.
    test('throws StateError when vault is not unlocked', () {
      expect(
        () => notifier.reSetup(uid: 'uid1', newPassphrase: 'pass'),
        throwsStateError,
      );
    });
  });
}
