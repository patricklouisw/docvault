/// Unit tests for [VaultRepository] — the data layer that orchestrates
/// crypto operations and persists vault metadata to Firestore.
///
/// Uses [MockCryptoService] (mocktail) for deterministic crypto stubs
/// and [FakeFirebaseFirestore] for an in-memory Firestore backend.
///
/// Coverage:
/// - [setupVault]: generates MK, salts, wraps keys, writes metadata
/// - [unlockWithPassphrase]: reads metadata, derives PDK, unwraps MK
/// - [unlockWithRecovery]: reads recovery metadata, derives RDK, unwraps MK
/// - [reSetupVault]: replaces all crypto metadata with fresh keys
/// - [_getCryptoMetadata]: throws StateError when crypto field is missing
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:docvault/features/vault/data/vault_repository.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockCryptoService mockCrypto;
  late VaultRepository repo;

  /// Deterministic test values used across all groups.
  final testMK = Uint8List.fromList(List.filled(32, 0xAB));
  final testSalt = Uint8List.fromList(List.filled(16, 0x01));
  final testRecoverySalt = Uint8List.fromList(List.filled(16, 0x02));
  final testSecretKey = SecretKey(List.filled(32, 0xCC));

  setUpAll(() {
    // Register fallback values for mocktail's any() matchers.
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(SecretKey([]));
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockCrypto = MockCryptoService();
    repo = VaultRepository(
      cryptoService: mockCrypto,
      firestore: fakeFirestore,
    );
  });

  // -- setupVault -------------------------------------------------------------

  group('setupVault', () {
    setUp(() {
      // Stub all crypto methods to return deterministic values.
      when(() => mockCrypto.generateMasterKey())
          .thenAnswer((_) async => testMK);
      when(() => mockCrypto.generateSalt())
          .thenAnswer((_) async => testSalt);
      when(() => mockCrypto.deriveKey(
            passphrase: any(named: 'passphrase'),
            salt: any(named: 'salt'),
            memory: any(named: 'memory'),
            iterations: any(named: 'iterations'),
            parallelism: any(named: 'parallelism'),
          )).thenAnswer((_) async => testSecretKey);
      when(() => mockCrypto.deriveKey(
            passphrase: any(named: 'passphrase'),
            salt: any(named: 'salt'),
          )).thenAnswer((_) async => testSecretKey);
      when(() => mockCrypto.wrapKey(
            keyToWrap: any(named: 'keyToWrap'),
            wrappingKey: any(named: 'wrappingKey'),
          )).thenAnswer((_) async => 'wrapped-base64-key');
      when(() => mockCrypto.generateRecoveryPhrase())
          .thenAnswer((_) async => 'word1 word2 word3');
    });

    /// setupVault must return both the raw MK (kept in memory) and
    /// the recovery phrase (shown to the user once).
    test('returns masterKey and recoveryPhrase', () async {
      final result = await repo.setupVault(
        uid: 'testuid',
        passphrase: 'mypassphrase',
      );

      expect(result.masterKey, equals(testMK));
      expect(result.recoveryPhrase, 'word1 word2 word3');
    });

    /// After setup, the Firestore user document should contain a
    /// `crypto` map with KDF algorithm, cipher, salt, wrapped MK,
    /// and a nested `recovery` map.
    test('writes crypto metadata to Firestore', () async {
      await repo.setupVault(
        uid: 'testuid',
        passphrase: 'mypassphrase',
      );

      final doc = await fakeFirestore
          .collection('users')
          .doc('testuid')
          .get();
      final data = doc.data()!;

      expect(data.containsKey('crypto'), isTrue);
      final crypto = data['crypto'] as Map<String, dynamic>;
      expect(crypto['kdf'], 'argon2id');
      expect(crypto['cipher'], 'xchacha20-poly1305');
      expect(crypto['keyVersion'], 1);
      expect(crypto['salt'], base64Encode(testSalt));
      expect(crypto['wrappedMasterKey'], 'wrapped-base64-key');

      final recovery = crypto['recovery'] as Map<String, dynamic>;
      expect(recovery['kdf'], 'argon2id');
      expect(recovery['cipher'], 'xchacha20-poly1305');
      expect(recovery['enabled'], isTrue);
      expect(recovery['wrappedMasterKey'], 'wrapped-base64-key');
    });

    /// Verify the exact call sequence: generate MK, generate salt,
    /// derive passphrase key, wrap MK with passphrase key, generate
    /// recovery phrase, generate recovery salt, derive recovery key,
    /// wrap MK with recovery key.
    test('calls crypto methods in correct order', () async {
      await repo.setupVault(
        uid: 'testuid',
        passphrase: 'mypassphrase',
      );

      verifyInOrder([
        () => mockCrypto.generateMasterKey(),
        () => mockCrypto.generateSalt(),
        () => mockCrypto.deriveKey(
              passphrase: 'mypassphrase',
              salt: any(named: 'salt'),
            ),
        () => mockCrypto.wrapKey(
              keyToWrap: testMK,
              wrappingKey: any(named: 'wrappingKey'),
            ),
        () => mockCrypto.generateRecoveryPhrase(),
        () => mockCrypto.generateSalt(),
        () => mockCrypto.deriveKey(
              passphrase: 'word1 word2 word3',
              salt: any(named: 'salt'),
            ),
        () => mockCrypto.wrapKey(
              keyToWrap: testMK,
              wrappingKey: any(named: 'wrappingKey'),
            ),
      ]);
    });
  });

  // -- unlockWithPassphrase ---------------------------------------------------

  group('unlockWithPassphrase', () {
    /// Reads KDF params from Firestore, derives the passphrase key,
    /// unwraps the MK, and returns it as raw bytes.
    test('returns masterKey for correct passphrase', () async {
      // Seed Firestore with crypto metadata.
      await fakeFirestore.collection('users').doc('uid1').set({
        'crypto': {
          'kdf': 'argon2id',
          'kdfParams': {'m': 1024, 't': 1, 'p': 1},
          'salt': base64Encode(testSalt),
          'wrappedMasterKey': 'wrapped-key-base64',
          'cipher': 'xchacha20-poly1305',
          'keyVersion': 1,
        },
      });

      when(() => mockCrypto.deriveKey(
            passphrase: any(named: 'passphrase'),
            salt: any(named: 'salt'),
            memory: any(named: 'memory'),
            iterations: any(named: 'iterations'),
            parallelism: any(named: 'parallelism'),
          )).thenAnswer((_) async => testSecretKey);
      when(() => mockCrypto.unwrapKey(
            wrappedKeyBase64: any(named: 'wrappedKeyBase64'),
            wrappingKey: any(named: 'wrappingKey'),
          )).thenAnswer((_) async => testMK);

      final mk = await repo.unlockWithPassphrase(
        uid: 'uid1',
        passphrase: 'mypassphrase',
      );

      expect(mk, equals(testMK));
      verify(() => mockCrypto.deriveKey(
            passphrase: 'mypassphrase',
            salt: any(named: 'salt'),
            memory: 1024,
            iterations: 1,
            parallelism: 1,
          )).called(1);
    });
  });

  // -- unlockWithRecovery -----------------------------------------------------

  group('unlockWithRecovery', () {
    /// Uses the recovery sub-document's salt and wrapped key instead
    /// of the passphrase path.
    test('returns masterKey for correct recovery phrase', () async {
      await fakeFirestore.collection('users').doc('uid1').set({
        'crypto': {
          'kdf': 'argon2id',
          'kdfParams': {'m': 1024, 't': 1, 'p': 1},
          'salt': base64Encode(testSalt),
          'wrappedMasterKey': 'wrapped-key-base64',
          'cipher': 'xchacha20-poly1305',
          'keyVersion': 1,
          'recovery': {
            'kdf': 'argon2id',
            'kdfParams': {'m': 1024, 't': 1, 'p': 1},
            'salt': base64Encode(testRecoverySalt),
            'wrappedMasterKey': 'recovery-wrapped-key',
            'cipher': 'xchacha20-poly1305',
            'enabled': true,
          },
        },
      });

      when(() => mockCrypto.deriveKey(
            passphrase: any(named: 'passphrase'),
            salt: any(named: 'salt'),
            memory: any(named: 'memory'),
            iterations: any(named: 'iterations'),
            parallelism: any(named: 'parallelism'),
          )).thenAnswer((_) async => testSecretKey);
      when(() => mockCrypto.unwrapKey(
            wrappedKeyBase64: any(named: 'wrappedKeyBase64'),
            wrappingKey: any(named: 'wrappingKey'),
          )).thenAnswer((_) async => testMK);

      final mk = await repo.unlockWithRecovery(
        uid: 'uid1',
        recoveryPhrase: 'word1 word2 word3',
      );

      expect(mk, equals(testMK));
      verify(() => mockCrypto.unwrapKey(
            wrappedKeyBase64: 'recovery-wrapped-key',
            wrappingKey: any(named: 'wrappingKey'),
          )).called(1);
    });
  });

  // -- reSetupVault -----------------------------------------------------------

  group('reSetupVault', () {
    /// After a recovery unlock the user must create a new passphrase.
    /// reSetupVault re-wraps the existing MK with a new PDK and
    /// generates a fresh recovery phrase.
    test('replaces all crypto metadata in Firestore', () async {
      // Seed existing data that will be fully replaced.
      await fakeFirestore.collection('users').doc('uid1').set({
        'crypto': {'old': 'data'},
      });

      when(() => mockCrypto.generateSalt())
          .thenAnswer((_) async => testSalt);
      when(() => mockCrypto.deriveKey(
            passphrase: any(named: 'passphrase'),
            salt: any(named: 'salt'),
          )).thenAnswer((_) async => testSecretKey);
      when(() => mockCrypto.wrapKey(
            keyToWrap: any(named: 'keyToWrap'),
            wrappingKey: any(named: 'wrappingKey'),
          )).thenAnswer((_) async => 'new-wrapped-key');
      when(() => mockCrypto.generateRecoveryPhrase())
          .thenAnswer((_) async => 'new recovery phrase');

      final phrase = await repo.reSetupVault(
        uid: 'uid1',
        masterKey: testMK,
        newPassphrase: 'newpass',
      );

      expect(phrase, 'new recovery phrase');

      final doc = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .get();
      final crypto =
          doc.data()!['crypto'] as Map<String, dynamic>;
      expect(crypto['wrappedMasterKey'], 'new-wrapped-key');
      expect(crypto['keyVersion'], 1);
      expect(crypto['recovery'], isNotNull);
    });
  });

  // -- _getCryptoMetadata (error path) ----------------------------------------

  group('_getCryptoMetadata', () {
    /// When the user document doesn't exist or has no `crypto` field,
    /// a StateError should be thrown before any crypto work happens.
    test('throws StateError when no crypto field exists', () {
      expect(
        () => repo.unlockWithPassphrase(
          uid: 'nonexistent',
          passphrase: 'pass',
        ),
        throwsStateError,
      );
    });
  });
}
