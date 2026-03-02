import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';

import 'package:docvault/core/services/crypto_service.dart';

/// Orchestrates crypto operations with Firestore persistence
/// for vault setup, unlock, and recovery flows.
class VaultRepository {
  VaultRepository({
    required CryptoService cryptoService,
    required FirebaseFirestore firestore,
  })  : _crypto = cryptoService,
        _firestore = firestore;

  final CryptoService _crypto;
  final FirebaseFirestore _firestore;

  /// Full vault setup: generate MK, derive PDK, wrap MK,
  /// generate recovery phrase + RDK, write crypto metadata.
  ///
  /// Returns the plaintext MK and the recovery phrase.
  Future<({Uint8List masterKey, String recoveryPhrase})>
      setupVault({
    required String uid,
    required String passphrase,
  }) async {
    log('Setting up vault for $uid', name: 'VaultRepository');

    // 1. Generate Master Key + passphrase salt
    final mk = await _crypto.generateMasterKey();
    final salt = await _crypto.generateSalt();

    // 2. Derive PDK from passphrase
    final pdk = await _crypto.deriveKey(
      passphrase: passphrase,
      salt: salt,
    );

    // 3. Wrap MK with PDK
    final wrappedMK = await _crypto.wrapKey(
      keyToWrap: mk,
      wrappingKey: pdk,
    );

    // 4. Generate recovery phrase + separate salt
    final recoveryPhrase =
        await _crypto.generateRecoveryPhrase();
    final recoverySalt = await _crypto.generateSalt();

    // 5. Derive RDK from recovery phrase
    final rdk = await _crypto.deriveKey(
      passphrase: recoveryPhrase,
      salt: recoverySalt,
    );

    // 6. Wrap MK with RDK
    final wrappedMKRecovery = await _crypto.wrapKey(
      keyToWrap: mk,
      wrappingKey: rdk,
    );

    // 7. Write crypto metadata to Firestore
    await _firestore.collection('users').doc(uid).set(
      {
        'crypto': {
          'kdf': 'argon2id',
          'kdfParams': {'m': 65536, 't': 3, 'p': 1},
          'salt': base64Encode(salt),
          'wrappedMasterKey': wrappedMK,
          'cipher': 'xchacha20-poly1305',
          'keyVersion': 1,
          'recovery': {
            'kdf': 'argon2id',
            'kdfParams': {'m': 65536, 't': 3, 'p': 1},
            'salt': base64Encode(recoverySalt),
            'wrappedMasterKey': wrappedMKRecovery,
            'cipher': 'xchacha20-poly1305',
            'enabled': true,
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    log('Vault setup complete for $uid',
        name: 'VaultRepository');

    return (masterKey: mk, recoveryPhrase: recoveryPhrase);
  }

  /// Unlock vault using passphrase.
  ///
  /// Fetches crypto metadata from Firestore, derives PDK,
  /// unwraps MK. Returns plaintext MK on success.
  /// Throws [SecretBoxAuthenticationError] on wrong passphrase.
  Future<Uint8List> unlockWithPassphrase({
    required String uid,
    required String passphrase,
  }) async {
    log('Unlocking vault with passphrase for $uid',
        name: 'VaultRepository');

    final crypto = await _getCryptoMetadata(uid);
    final kdfParams =
        crypto['kdfParams'] as Map<String, dynamic>;

    final salt = base64Decode(crypto['salt'] as String);

    // Derive PDK
    final pdk = await _crypto.deriveKey(
      passphrase: passphrase,
      salt: Uint8List.fromList(salt),
      memory: kdfParams['m'] as int,
      iterations: kdfParams['t'] as int,
      parallelism: kdfParams['p'] as int,
    );

    // Unwrap MK (throws on wrong passphrase)
    return _crypto.unwrapKey(
      wrappedKeyBase64: crypto['wrappedMasterKey'] as String,
      wrappingKey: pdk,
    );
  }

  /// Unlock vault using recovery phrase.
  ///
  /// Fetches recovery metadata from Firestore, derives RDK,
  /// unwraps MK. Returns plaintext MK on success.
  /// Throws [SecretBoxAuthenticationError] on wrong phrase.
  Future<Uint8List> unlockWithRecovery({
    required String uid,
    required String recoveryPhrase,
  }) async {
    log('Unlocking vault with recovery phrase for $uid',
        name: 'VaultRepository');

    final crypto = await _getCryptoMetadata(uid);
    final recovery =
        crypto['recovery'] as Map<String, dynamic>;
    final kdfParams =
        recovery['kdfParams'] as Map<String, dynamic>;

    final salt = base64Decode(recovery['salt'] as String);

    // Derive RDK
    final rdk = await _crypto.deriveKey(
      passphrase: recoveryPhrase,
      salt: Uint8List.fromList(salt),
      memory: kdfParams['m'] as int,
      iterations: kdfParams['t'] as int,
      parallelism: kdfParams['p'] as int,
    );

    // Unwrap MK (throws on wrong recovery phrase)
    return _crypto.unwrapKey(
      wrappedKeyBase64:
          recovery['wrappedMasterKey'] as String,
      wrappingKey: rdk,
    );
  }

  /// Reset passphrase after recovery unlock.
  ///
  /// Re-wraps existing MK with new PDK derived from new passphrase.
  /// Updates Firestore crypto metadata (salt, wrappedMasterKey).
  Future<void> resetPassphrase({
    required String uid,
    required Uint8List masterKey,
    required String newPassphrase,
  }) async {
    log('Resetting passphrase for $uid',
        name: 'VaultRepository');

    final newSalt = await _crypto.generateSalt();

    final newPdk = await _crypto.deriveKey(
      passphrase: newPassphrase,
      salt: newSalt,
    );

    final newWrappedMK = await _crypto.wrapKey(
      keyToWrap: masterKey,
      wrappingKey: newPdk,
    );

    await _firestore.collection('users').doc(uid).set(
      {
        'crypto': {
          'salt': base64Encode(newSalt),
          'wrappedMasterKey': newWrappedMK,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    log('Passphrase reset complete for $uid',
        name: 'VaultRepository');
  }

  /// Re-setup vault after recovery unlock.
  ///
  /// Re-wraps existing MK with a new passphrase AND generates
  /// a new recovery phrase. Replaces all crypto metadata.
  Future<String> reSetupVault({
    required String uid,
    required Uint8List masterKey,
    required String newPassphrase,
  }) async {
    log('Re-setting up vault for $uid',
        name: 'VaultRepository');

    // 1. New passphrase salt + PDK
    final salt = await _crypto.generateSalt();
    final pdk = await _crypto.deriveKey(
      passphrase: newPassphrase,
      salt: salt,
    );

    // 2. Wrap MK with new PDK
    final wrappedMK = await _crypto.wrapKey(
      keyToWrap: masterKey,
      wrappingKey: pdk,
    );

    // 3. Generate new recovery phrase + salt
    final recoveryPhrase =
        await _crypto.generateRecoveryPhrase();
    final recoverySalt = await _crypto.generateSalt();

    // 4. Derive RDK from new recovery phrase
    final rdk = await _crypto.deriveKey(
      passphrase: recoveryPhrase,
      salt: recoverySalt,
    );

    // 5. Wrap MK with new RDK
    final wrappedMKRecovery = await _crypto.wrapKey(
      keyToWrap: masterKey,
      wrappingKey: rdk,
    );

    // 6. Replace crypto metadata in Firestore
    await _firestore.collection('users').doc(uid).set(
      {
        'crypto': {
          'kdf': 'argon2id',
          'kdfParams': {'m': 65536, 't': 3, 'p': 1},
          'salt': base64Encode(salt),
          'wrappedMasterKey': wrappedMK,
          'cipher': 'xchacha20-poly1305',
          'keyVersion': 1,
          'recovery': {
            'kdf': 'argon2id',
            'kdfParams': {'m': 65536, 't': 3, 'p': 1},
            'salt': base64Encode(recoverySalt),
            'wrappedMasterKey': wrappedMKRecovery,
            'cipher': 'xchacha20-poly1305',
            'enabled': true,
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    log('Vault re-setup complete for $uid',
        name: 'VaultRepository');

    return recoveryPhrase;
  }

  /// Fetches the crypto metadata from Firestore.
  /// Throws [StateError] if no crypto metadata exists.
  Future<Map<String, dynamic>> _getCryptoMetadata(
    String uid,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .get();
    final data = snapshot.data();
    if (data == null || !data.containsKey('crypto')) {
      throw StateError(
        'No crypto metadata found for user $uid',
      );
    }
    return data['crypto'] as Map<String, dynamic>;
  }
}
