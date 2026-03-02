import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'package:docvault/core/constants/bip39_english.dart';

/// Pure cryptographic primitives for vault encryption.
/// No Firestore dependencies, no state.
class CryptoService {
  final _aead = Xchacha20.poly1305Aead();

  /// Generate a cryptographically random 32-byte Master Key.
  Future<Uint8List> generateMasterKey() async {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
  }

  /// Generate a cryptographically random 16-byte salt.
  Future<Uint8List> generateSalt() async {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
  }

  /// Derive a 32-byte key from passphrase + salt using Argon2id.
  Future<SecretKey> deriveKey({
    required String passphrase,
    required Uint8List salt,
    int memory = 65536,
    int iterations = 3,
    int parallelism = 1,
  }) async {
    final kdf = Argon2id(
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: 32,
    );

    return kdf.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
  }

  /// Wrap (encrypt) a key using XChaCha20-Poly1305.
  ///
  /// Returns a base64 string containing:
  /// `nonce (24 bytes) || ciphertext || mac (16 bytes)`.
  Future<String> wrapKey({
    required Uint8List keyToWrap,
    required SecretKey wrappingKey,
  }) async {
    final secretBox = await _aead.encrypt(
      keyToWrap,
      secretKey: wrappingKey,
    );

    // Concatenate: nonce + ciphertext + mac
    final combined = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return base64Encode(combined);
  }

  /// Unwrap (decrypt) a key using XChaCha20-Poly1305.
  ///
  /// [wrappedKeyBase64] is the base64 string produced by [wrapKey]:
  /// `nonce (24 bytes) || ciphertext || mac (16 bytes)`.
  ///
  /// Returns the unwrapped key bytes.
  /// Throws [SecretBoxAuthenticationError] if the wrapping key is
  /// wrong (i.e. wrong passphrase).
  Future<Uint8List> unwrapKey({
    required String wrappedKeyBase64,
    required SecretKey wrappingKey,
  }) async {
    final combined = base64Decode(wrappedKeyBase64);

    // XChaCha20-Poly1305 nonce is 24 bytes, MAC is 16 bytes
    const nonceLength = 24;
    const macLength = 16;

    final nonce = combined.sublist(0, nonceLength);
    final cipherText = combined.sublist(
      nonceLength,
      combined.length - macLength,
    );
    final macBytes = combined.sublist(combined.length - macLength);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await _aead.decrypt(
      secretBox,
      secretKey: wrappingKey,
    );

    return Uint8List.fromList(plaintext);
  }

  /// Generate a 12-word recovery phrase from 128 bits of entropy.
  ///
  /// Each word is selected from the BIP39 English word list (2048 words).
  /// 128 bits / 11 bits per word ≈ 11.6 words; we use 12 words
  /// (132 bits total, last 4 bits padded).
  Future<String> generateRecoveryPhrase() async {
    final random = Random.secure();
    // 16 bytes = 128 bits of entropy
    final entropy = Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );

    // Convert entropy bytes to a bit string
    final bits = entropy
        .map((byte) => byte.toRadixString(2).padLeft(8, '0'))
        .join();

    // Pick 12 words using 11-bit chunks
    final words = <String>[];
    for (var i = 0; i < 12; i++) {
      final start = i * 11;
      // Pad with zeros if we run past the bit string
      final chunk = bits.substring(
        start,
        min(start + 11, bits.length),
      );
      final index =
          int.parse(chunk.padRight(11, '0'), radix: 2) % 2048;
      words.add(bip39EnglishWords[index]);
    }

    return words.join(' ');
  }
}
