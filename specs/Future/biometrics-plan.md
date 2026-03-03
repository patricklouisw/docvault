# Biometric Unlock — Implementation Plan

## Context

Users currently type their vault passphrase every time they open the app (MK is erased from memory on close/crash/logout). Biometric unlock (Face ID, Touch ID, fingerprint) would let them skip the passphrase on supported devices, providing instant access while maintaining zero-knowledge security.

Biometric unlock belongs at the **vault unlock stage**, not the sign-in stage, because:
- Sign-in happens rarely (Firebase keeps sessions alive). Vault unlock happens **every app open** — that's where the friction is.
- Biometrics gate access to a stored secret in the device's secure enclave, which can then unwrap the Master Key. This is cryptographically meaningful.
- Firebase Auth still needs its own credential — biometrics can't produce one.
- Zero-knowledge is preserved: the secret never leaves the device.

---

## Design Decision: How to Store the Biometric Secret

### Approach chosen: Biometric Key (BK) wraps MK independently

Generate a random 32-byte Biometric Key (BK), store it in the device's secure enclave (iOS Keychain / Android Keystore) protected by biometric authentication, and wrap MK with BK separately — just like passphrase and recovery phrase each wrap MK independently.

```
MK is now wrapped 3 ways (like 3 different locks on the same safe):

  1. By PDK (from passphrase + Argon2id)     — stored in Firestore crypto.wrappedMasterKey
  2. By RDK (from recovery phrase + Argon2id) — stored in Firestore crypto.recovery.wrappedMasterKey
  3. By BK  (random key in secure enclave)    — stored in Firestore biometric.wrappedMasterKey
```

### Why this approach over alternatives

| Approach | Pros | Cons |
|----------|------|------|
| **A: Store passphrase in secure storage** | Simplest, no Firestore changes | Argon2id runs every biometric unlock (1-3s delay defeats the point). Breaks when passphrase changes |
| **B: Store PDK in secure storage** | No Firestore changes, fast unlock | Breaks when passphrase changes (new salt = new PDK). Tied to passphrase lifecycle |
| **C: Store random BK, wrap MK separately (chosen)** | Fast (no Argon2id). Independent of passphrase. Survives passphrase changes and recovery re-setup. Follows existing wrapping pattern | Requires Firestore schema addition. More implementation work |

### Why store `biometric` as a separate top-level Firestore field

Both `setupVault()` and `reSetupVault()` use `set({crypto: {...}}, merge: true)` which **replaces the entire `crypto` object**. If biometric data were inside `crypto`, it would be wiped during vault setup or recovery re-setup.

Storing it separately at `users/{uid}/biometric` keeps it safe. And since MK doesn't change during recovery re-setup, the biometric wrapping remains valid.

---

## Dependencies

```yaml
local_auth: ^2.3.0               # Biometric availability check + auth prompt
flutter_secure_storage: ^10.0.0   # Store BK in Keychain/Keystore with biometric protection
```

- **`local_auth`** — Checks if device supports biometrics, triggers the OS biometric prompt. Wraps `BiometricPrompt` (Android) and `LocalAuthentication` (iOS).
- **`flutter_secure_storage`** — Stores the BK in the platform's secure enclave, gated by biometric authentication. v10 has a rewritten Android implementation with custom ciphers and enhanced biometric support.

---

## Firestore Schema Addition

```
users/{uid}:
  crypto: { ... existing, untouched ... }
  biometric:                                    <-- NEW separate top-level field
    wrappedMasterKey: "<base64: nonce || ct || mac>"
    cipher: "xchacha20-poly1305"
    enabled: true
```

No `salt` or `kdfParams` needed — BK is already a random 32-byte cryptographic key, not a human-memorable string. No Argon2id derivation required.

---

## Implementation Steps

### Step 1: Add dependencies
- Add `local_auth` and `flutter_secure_storage` to `pubspec.yaml`
- **iOS:** Add `NSFaceIDUsageDescription` to `ios/Runner/Info.plist`
- **Android:** Add `USE_BIOMETRIC` permission to `android/app/src/main/AndroidManifest.xml`, change `MainActivity` to extend `FlutterFragmentActivity` (required by `local_auth`)

### Step 2: BiometricService — `lib/core/services/biometric_service.dart`
New service class encapsulating device biometric operations:

```dart
class BiometricService {
  // Check if device supports biometrics AND has enrolled biometrics
  Future<bool> isAvailable();

  // Trigger OS biometric prompt (Face ID / fingerprint)
  Future<bool> authenticate({required String reason});

  // Store BK in secure storage with biometric access control
  Future<void> storeBiometricKey(Uint8List bk);

  // Retrieve BK from secure storage (triggers biometric via OS)
  Future<Uint8List?> retrieveBiometricKey();

  // Remove BK from secure storage
  Future<void> deleteBiometricKey();
}
```

### Step 3: Update VaultRepository — add biometric methods

```dart
// Enable biometric unlock (called when user toggles ON in settings)
Future<void> enableBiometric({
  required String uid,
  required Uint8List masterKey,
}) async {
  // 1. Generate random BK (32 bytes)
  // 2. Store BK in BiometricService (secure enclave)
  // 3. Wrap MK with BK via CryptoService.wrapKey()
  // 4. Write biometric field to Firestore users/{uid} (separate from crypto)
}

// Disable biometric unlock (called when user toggles OFF)
Future<void> disableBiometric({required String uid}) async {
  // 1. Delete BK from BiometricService
  // 2. Delete biometric field from Firestore
}

// Unlock vault using biometric (called on vault unlock screen)
Future<Uint8List> unlockWithBiometric({required String uid}) async {
  // 1. Retrieve BK from BiometricService (triggers biometric prompt)
  // 2. Fetch biometric.wrappedMasterKey from Firestore
  // 3. Unwrap MK with BK → return plaintext MK
}

// Check if biometric is enabled for this user
Future<bool> hasBiometricEnabled({required String uid});
```

### Step 4: Update VaultNotifier — add biometric state methods

```dart
// Unlock vault with biometric
Future<void> unlockWithBiometric({required String uid});

// Enable biometric — only callable when vault is VaultUnlocked (MK in memory)
Future<void> enableBiometric({required String uid});

// Disable biometric
Future<void> disableBiometric({required String uid});
```

### Step 5: Providers
- `biometricServiceProvider` — provides `BiometricService` singleton
- Wire `BiometricService` into `VaultRepository` provider

### Step 6: Update AppStrings
Add biometric-related UI strings:
- `unlockWithBiometrics` / `enableBiometricUnlock` / `disableBiometricUnlock`
- `biometricFailed` / `biometricNotAvailable` / `biometricReason`

### Step 7: Update VaultUnlockScreen
- On screen load: check biometric availability + enabled status
- If biometric enabled: show biometric icon button, **auto-trigger biometric prompt**
- `_onBiometricUnlock()`: calls `vaultNotifier.unlockWithBiometric(uid)` → navigate to home on success
- Fallback: user can always tap passphrase field to type manually
- Error handling: biometric failure shows message, doesn't block passphrase input

### Step 8: Update ProfileScreen — biometric toggle
- Add "Security" section between user info and log out button
- `SwitchListTile` for "Unlock with Face ID / Fingerprint"
- **Toggle ON:** prompt passphrase to confirm identity → call `vaultNotifier.enableBiometric(uid)`
- **Toggle OFF:** call `vaultNotifier.disableBiometric(uid)`
- Only show toggle if `biometricService.isAvailable()` returns true

### Step 9: Handle edge cases
See edge cases section below.

---

## Files Changed

### New files (1):

| File | Purpose |
|------|---------|
| `lib/core/services/biometric_service.dart` | Device biometric operations (check, authenticate, store/retrieve BK) |

### Modified files (8):

| File | Changes |
|------|---------|
| `pubspec.yaml` | Add `local_auth`, `flutter_secure_storage` |
| `ios/Runner/Info.plist` | Add `NSFaceIDUsageDescription` |
| `android/app/src/main/AndroidManifest.xml` | Add `USE_BIOMETRIC` permission |
| `android/app/src/main/kotlin/.../MainActivity.kt` | Extend `FlutterFragmentActivity` |
| `lib/features/vault/data/vault_repository.dart` | Add `enableBiometric()`, `disableBiometric()`, `unlockWithBiometric()`, `hasBiometricEnabled()` |
| `lib/features/vault/domain/vault_provider.dart` | Add biometric methods to VaultNotifier, add `biometricServiceProvider` |
| `lib/core/constants/app_strings.dart` | Add biometric UI strings |
| `lib/features/auth/presentation/vault_unlock_screen.dart` | Add biometric button, auto-trigger on load, `_onBiometricUnlock()` |
| `lib/features/home/presentation/profile_screen.dart` | Add biometric toggle in security section |

---

## User Flows

### Enabling biometric (from Profile settings)

```
Profile → Security → "Unlock with Face ID" toggle ON
  → Enter passphrase to confirm identity
  → [Biometric prompt to register]
  → BK generated, stored in device secure enclave
  → MK wrapped with BK, saved to Firestore biometric field
  → Toggle shows ON
```

What happens behind the scenes:

```
1. User enters passphrase → confirms identity (prevents someone with
   physical access from enabling biometric on a stolen unlocked phone)
2. Generate random BK (32 bytes)
3. Store BK in Keychain/Keystore with biometric access control
4. XChaCha20-Poly1305.encrypt(MK, using BK) → biometric wrappedMK
5. Write to Firestore users/{uid}:
   {
     biometric: {
       wrappedMasterKey: "<base64>",
       cipher: "xchacha20-poly1305",
       enabled: true
     }
   }
```

### Unlocking with biometric (daily use)

```
App opens → Vault Unlock screen
  → Biometric prompt auto-appears (Face ID / fingerprint)
  → OS releases BK from secure enclave
  → BK unwraps MK from Firestore → VaultUnlocked
  → Home screen (instant — no Argon2id delay!)
```

What happens behind the scenes:

```
1. VaultUnlockScreen loads → checks biometricService.isAvailable()
   AND hasBiometricEnabled(uid)
2. Auto-triggers BiometricService.retrieveBiometricKey()
   → OS shows Face ID / fingerprint prompt
3. Success → BK released from secure enclave
4. Fetch biometric.wrappedMasterKey from Firestore
5. XChaCha20-Poly1305.decrypt(wrappedMK, using BK) → MK
6. VaultNotifier.state = VaultUnlocked(MK)
7. Navigate to home
```

### Biometric fails or unavailable

```
Biometric prompt fails / user cancels / wet fingers / etc.
  → Dismiss prompt, show passphrase input field
  → "Use passphrase instead" (always available as fallback)
  → Normal passphrase unlock flow (with Argon2id, 1-3s)
```

### Disabling biometric

```
Profile → Security → "Unlock with Face ID" toggle OFF
  → BiometricService.deleteBiometricKey() (BK removed from device)
  → Delete biometric field from Firestore
  → Toggle shows OFF
  → Next app open: passphrase-only unlock
```

---

## Edge Cases

| Scenario | What happens | Action needed |
|----------|-------------|---------------|
| **Recovery re-setup** | MK stays the same → biometric wrappedMK in Firestore is still valid, BK in secure enclave still works | None — biometric survives recovery re-setup |
| **Logout** | MK erased from memory. BK stays in secure enclave, biometric wrappedMK stays in Firestore | Biometric works on next login — no re-enable needed |
| **New device** | BK is device-specific (Keychain/Keystore not portable) → BK doesn't exist on new device | Fall back to passphrase. User re-enables biometric in settings on new device |
| **User re-registers fingerprints** | iOS invalidates Keychain entries with `kSecAccessControlBiometryCurrentSet`. Android similar | BK lost → retrieveBiometricKey returns null → fall back to passphrase. Auto-disable biometric flag |
| **App reinstall** | iOS Keychain may persist (by default). Android Keystore entries cleared | Handle gracefully: if BK retrieval fails, fall back to passphrase |
| **Device has no biometrics** | `isAvailable()` returns false | Toggle not shown in Profile. No biometric button on unlock screen |
| **User adds biometrics later** | Device initially had none, user enrolls fingerprint | Toggle appears in Profile next time they check. They can enable it |
| **Biometric prompt cancelled** | User taps "Cancel" on Face ID / fingerprint prompt | Show passphrase input. Don't auto-re-trigger (annoying). User can tap biometric icon to retry |

---

## Security Considerations

- **BK never leaves the secure enclave** — `flutter_secure_storage` ensures BK is hardware-protected
- **Biometric data stays on-device** — the OS handles matching, app never sees fingerprint/face data
- **Passphrase confirmation on enable** — prevents someone with physical access from enabling biometric on an already-unlocked phone
- **Zero-knowledge preserved** — BK and biometric wrappedMK together can only produce MK on the device. Server sees only encrypted blob
- **Not a replacement for passphrase** — biometric is a convenience layer. Passphrase and recovery phrase remain the primary and backup unlock methods
- **Rate limiting** — OS enforces biometric attempt limits (e.g., iOS locks out after 5 failures, requires device passcode)

---

## Verification Checklist

1. `flutter pub get` + `flutter analyze` pass
2. On device with biometrics: enable toggle in Profile → verify BK stored
3. Close and reopen app → biometric prompt appears → unlocks instantly (no Argon2id delay)
4. Wrong fingerprint / cancel → can still type passphrase
5. Recovery re-setup → biometric still works afterward (MK unchanged)
6. Disable toggle → biometric prompt no longer appears on unlock screen
7. On device without biometrics → toggle not shown in Profile
8. Logout → reopen → biometric still works (BK persisted in secure storage)
