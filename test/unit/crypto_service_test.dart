/// Unit tests for [CryptoService] — the zero-knowledge encryption layer.
///
/// These tests exercise **real** crypto operations (no mocks) to verify
/// that the service produces correct key material and that the
/// wrap / unwrap round-trip is faithful. Argon2id params are set to
/// the minimum (`memory: 1024, iterations: 1`) for fast test execution.
///
/// Coverage:
/// - [CryptoService.generateMasterKey]: 32-byte random key, uniqueness
/// - [CryptoService.generateSalt]: 16-byte random salt, uniqueness
/// - [CryptoService.deriveKey]: determinism, sensitivity to passphrase
///   and salt changes
/// - [CryptoService.wrapKey] / [CryptoService.unwrapKey]: round-trip
///   integrity and authentication failure on wrong key
/// - [CryptoService.generateRecoveryPhrase]: 12 BIP-39 words
library;

import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docvault/core/constants/bip39_english.dart';
import 'package:docvault/core/services/crypto_service.dart';

void main() {
  late CryptoService crypto;

  setUp(() {
    crypto = CryptoService();
  });

  // -- generateMasterKey ------------------------------------------------------

  group('generateMasterKey', () {
    /// MK must be exactly 256 bits (32 bytes) for XChaCha20-Poly1305.
    test('returns 32 bytes', () async {
      final key = await crypto.generateMasterKey();
      expect(key.length, 32);
    });

    /// Each call should produce cryptographically unique output.
    test('returns different values on successive calls', () async {
      final k1 = await crypto.generateMasterKey();
      final k2 = await crypto.generateMasterKey();
      expect(k1, isNot(equals(k2)));
    });
  });

  // -- generateSalt -----------------------------------------------------------

  group('generateSalt', () {
    /// Salt must be 128 bits (16 bytes) per Argon2id recommendation.
    test('returns 16 bytes', () async {
      final salt = await crypto.generateSalt();
      expect(salt.length, 16);
    });

    /// Salts should never repeat across calls.
    test('returns different values on successive calls', () async {
      final s1 = await crypto.generateSalt();
      final s2 = await crypto.generateSalt();
      expect(s1, isNot(equals(s2)));
    });
  });

  // -- deriveKey (Argon2id) ---------------------------------------------------

  group('deriveKey', () {
    // Use low Argon2id params so tests run in milliseconds, not seconds.
    const memory = 1024;
    const iterations = 1;
    const parallelism = 1;

    /// Deriving a key should produce a 256-bit SecretKey.
    test('produces a SecretKey from passphrase + salt', () async {
      final salt = Uint8List.fromList(List.filled(16, 42));
      final key = await crypto.deriveKey(
        passphrase: 'test-passphrase',
        salt: salt,
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
      );
      final bytes = await key.extractBytes();
      expect(bytes.length, 32);
    });

    /// Argon2id is deterministic: same inputs must yield identical keys.
    test('same input produces same key (deterministic)', () async {
      final salt = Uint8List.fromList(List.filled(16, 42));
      final k1 = await crypto.deriveKey(
        passphrase: 'test-passphrase',
        salt: salt,
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
      );
      final k2 = await crypto.deriveKey(
        passphrase: 'test-passphrase',
        salt: salt,
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
      );
      expect(await k1.extractBytes(), await k2.extractBytes());
    });

    /// Changing the passphrase must produce a completely different key.
    test('different passphrase produces different key', () async {
      final salt = Uint8List.fromList(List.filled(16, 42));
      final k1 = await crypto.deriveKey(
        passphrase: 'passphrase-one',
        salt: salt,
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
      );
      final k2 = await crypto.deriveKey(
        passphrase: 'passphrase-two',
        salt: salt,
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
      );
      expect(await k1.extractBytes(), isNot(await k2.extractBytes()));
    });

    /// Changing the salt must produce a completely different key.
    test('different salt produces different key', () async {
      final s1 = Uint8List.fromList(List.filled(16, 1));
      final s2 = Uint8List.fromList(List.filled(16, 2));
      final k1 = await crypto.deriveKey(
        passphrase: 'same-passphrase',
        salt: s1,
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
      );
      final k2 = await crypto.deriveKey(
        passphrase: 'same-passphrase',
        salt: s2,
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
      );
      expect(await k1.extractBytes(), isNot(await k2.extractBytes()));
    });
  });

  // -- wrapKey / unwrapKey (XChaCha20-Poly1305) --------------------------------

  group('wrapKey / unwrapKey', () {
    /// Wrapping then unwrapping with the same key must recover the
    /// original plaintext master key byte-for-byte.
    test('round-trip recovers original key', () async {
      final salt = Uint8List.fromList(List.filled(16, 99));
      final wrappingKey = await crypto.deriveKey(
        passphrase: 'wrap-passphrase',
        salt: salt,
        memory: 1024,
        iterations: 1,
        parallelism: 1,
      );

      final originalKey = await crypto.generateMasterKey();
      final wrapped = await crypto.wrapKey(
        keyToWrap: originalKey,
        wrappingKey: wrappingKey,
      );
      final unwrapped = await crypto.unwrapKey(
        wrappedKeyBase64: wrapped,
        wrappingKey: wrappingKey,
      );

      expect(unwrapped, equals(originalKey));
    });

    /// Attempting to unwrap with the wrong key must throw a
    /// [SecretBoxAuthenticationError] (authenticated encryption
    /// detects tampering / wrong key).
    test('wrong key throws SecretBoxAuthenticationError', () async {
      final salt = Uint8List.fromList(List.filled(16, 99));
      final correctKey = await crypto.deriveKey(
        passphrase: 'correct',
        salt: salt,
        memory: 1024,
        iterations: 1,
        parallelism: 1,
      );
      final wrongKey = await crypto.deriveKey(
        passphrase: 'wrong-key',
        salt: salt,
        memory: 1024,
        iterations: 1,
        parallelism: 1,
      );

      final originalKey = await crypto.generateMasterKey();
      final wrapped = await crypto.wrapKey(
        keyToWrap: originalKey,
        wrappingKey: correctKey,
      );

      expect(
        () => crypto.unwrapKey(
          wrappedKeyBase64: wrapped,
          wrappingKey: wrongKey,
        ),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });

  // -- generateRecoveryPhrase -------------------------------------------------

  group('generateRecoveryPhrase', () {
    /// Recovery phrase must consist of exactly 12 space-separated words.
    test('returns exactly 12 words', () async {
      final phrase = await crypto.generateRecoveryPhrase();
      final words = phrase.split(' ');
      expect(words.length, 12);
    });

    /// Every word in the phrase must belong to the BIP-39 English
    /// word list to ensure cross-wallet compatibility.
    test('all words are from BIP39 list', () async {
      final phrase = await crypto.generateRecoveryPhrase();
      final words = phrase.split(' ');
      for (final word in words) {
        expect(
          bip39EnglishWords.contains(word),
          isTrue,
          reason: '"$word" is not in BIP39 word list',
        );
      }
    });
  });
}
