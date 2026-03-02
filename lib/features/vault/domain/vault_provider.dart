import 'dart:developer';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docvault/core/services/crypto_service.dart';
import 'package:docvault/features/vault/data/vault_repository.dart';

// ---------------------------------------------------------------------------
// Vault state
// ---------------------------------------------------------------------------

/// Sealed class representing the current state of the vault.
sealed class VaultState {
  const VaultState();
}

/// Vault is locked — MK not in memory.
class VaultLocked extends VaultState {
  const VaultLocked();
}

/// Vault is unlocked — MK available in memory.
class VaultUnlocked extends VaultState {
  const VaultUnlocked(this.masterKey);
  final Uint8List masterKey;
}

/// User has no crypto metadata — vault setup required.
class VaultSetupRequired extends VaultState {
  const VaultSetupRequired();
}

/// An error occurred during a vault operation.
class VaultError extends VaultState {
  const VaultError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Vault notifier
// ---------------------------------------------------------------------------

/// Manages the vault lifecycle: setup, unlock, lock, reset.
class VaultNotifier extends StateNotifier<VaultState> {
  VaultNotifier({required VaultRepository vaultRepository})
      : _vaultRepository = vaultRepository,
        super(const VaultLocked());

  final VaultRepository _vaultRepository;

  /// Set up vault during sign-up.
  ///
  /// Generates MK, wraps it with passphrase + recovery phrase,
  /// writes crypto metadata to Firestore.
  /// Returns the recovery phrase to display to the user.
  Future<String> setup({
    required String uid,
    required String passphrase,
  }) async {
    final result = await _vaultRepository.setupVault(
      uid: uid,
      passphrase: passphrase,
    );
    state = VaultUnlocked(result.masterKey);
    return result.recoveryPhrase;
  }

  /// Unlock vault with passphrase.
  ///
  /// Throws [SecretBoxAuthenticationError] on wrong passphrase.
  Future<void> unlockWithPassphrase({
    required String uid,
    required String passphrase,
  }) async {
    final mk = await _vaultRepository.unlockWithPassphrase(
      uid: uid,
      passphrase: passphrase,
    );
    state = VaultUnlocked(mk);
  }

  /// Unlock vault with recovery phrase.
  ///
  /// Throws [SecretBoxAuthenticationError] on wrong phrase.
  Future<void> unlockWithRecovery({
    required String uid,
    required String recoveryPhrase,
  }) async {
    final mk = await _vaultRepository.unlockWithRecovery(
      uid: uid,
      recoveryPhrase: recoveryPhrase,
    );
    state = VaultUnlocked(mk);
  }

  /// Lock the vault and clear MK from memory.
  void lock() {
    final current = state;
    if (current is VaultUnlocked) {
      // Best-effort zeroing of MK bytes before releasing
      current.masterKey.fillRange(
        0,
        current.masterKey.length,
        0,
      );
      log(
        'Master key zeroed and vault locked',
        name: 'VaultNotifier',
      );
    }
    state = const VaultLocked();
  }

  /// Mark vault as needing setup.
  void setSetupRequired() {
    state = const VaultSetupRequired();
  }

  /// Re-setup vault after recovery unlock.
  ///
  /// Re-wraps existing MK with new passphrase and generates
  /// a new recovery phrase. Only callable when vault is unlocked.
  /// Returns the new recovery phrase.
  Future<String> reSetup({
    required String uid,
    required String newPassphrase,
  }) async {
    final current = state;
    if (current is! VaultUnlocked) {
      throw StateError(
        'Cannot re-setup vault when vault is not unlocked',
      );
    }
    return _vaultRepository.reSetupVault(
      uid: uid,
      masterKey: current.masterKey,
      newPassphrase: newPassphrase,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final cryptoServiceProvider = Provider<CryptoService>(
  (ref) => CryptoService(),
);

final vaultRepositoryProvider = Provider<VaultRepository>(
  (ref) => VaultRepository(
    cryptoService: ref.watch(cryptoServiceProvider),
    firestore: FirebaseFirestore.instance,
  ),
);

final vaultProvider =
    StateNotifierProvider<VaultNotifier, VaultState>(
  (ref) => VaultNotifier(
    vaultRepository: ref.watch(vaultRepositoryProvider),
  ),
);
