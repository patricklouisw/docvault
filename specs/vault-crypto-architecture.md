# Vault Crypto Architecture

## What is the Vault?

Think of DocVault like a safe deposit box at a bank. You put your documents inside, lock it with a passphrase only you know, and even the bank (our servers) can't peek inside. This is called **zero-knowledge encryption** — the server stores your stuff but has zero knowledge of what's inside.

---

## The Key Hierarchy — How the Locks Work

Imagine a chain of locks, each protecting the next:

```
You remember this
       |
       v
┌─────────────────┐
│  Vault Passphrase │  ← The one thing you memorize (or recovery phrase)
└────────┬────────┘
         │  Argon2id (slow, intentional — makes guessing hard)
         v
┌─────────────────┐
│  PDK             │  ← Password-Derived Key (temporary, never stored)
│  (32 bytes)      │
└────────┬────────┘
         │  Unwraps (decrypts)
         v
┌─────────────────┐
│  Master Key (MK) │  ← The real key that locks/unlocks everything
│  (32 bytes)      │     Lives ONLY in phone memory while app is open
└────────┬────────┘
         │  Unwraps (decrypts)
         v
┌─────────────────┐
│  File Key (FK)   │  ← Each document gets its own unique key
│  (32 bytes)      │     (Feature 2 — not implemented yet)
└─────────────────┘
```

### Why so many keys?

- **Passphrase** — You can change it without re-encrypting every file
- **Master Key** — One key to rule them all, but it never touches the server in readable form
- **File Keys** — If one file key leaks somehow, other files stay safe

---

## Algorithms Used

| What | Algorithm | Why |
|------|-----------|-----|
| Turning your passphrase into a key | **Argon2id** (m=65536, t=3, p=1) | Intentionally slow — uses 64MB of RAM and 3 passes. Makes brute-force guessing extremely expensive |
| Wrapping (encrypting) keys | **XChaCha20-Poly1305** | Modern, fast, large nonce (192-bit) means we never worry about nonce collisions |
| Recovery phrase words | **BIP39 English word list** (2048 words) | Well-known standard, 12 words = 128 bits of randomness |

---

## User Flows

### Flow 1: First-Time Sign-Up (Setting Up the Vault)

What the user sees:

```
Step 1: Fill in profile (name, phone, etc.)
Step 2: Create account (email + password) → Firebase account created
Step 3: "Secure Your Vault" → enter a vault passphrase
         [Loading spinner while crypto runs...]
Step 4: "Your Recovery Phrase" → shown 12 random words
         [Must check "I have saved my recovery phrase"]
         → Enters the app
```

What happens behind the scenes during Step 3 → Step 4:

```
┌──────────────────────────────────────────────────────────────────┐
│ STEP 3: User taps "Continue" with passphrase                    │
│                                                                  │
│  1. Generate Master Key (32 random bytes)                        │
│  2. Generate Salt A (16 random bytes) — for passphrase           │
│  3. Argon2id(passphrase + Salt A) → PDK                         │
│  4. XChaCha20-Poly1305.encrypt(MK, using PDK) → wrappedMK      │
│                                                                  │
│  5. Pick 12 random words → recovery phrase                       │
│  6. Generate Salt B (16 random bytes) — for recovery (SEPARATE!) │
│  7. Argon2id(recovery phrase + Salt B) → RDK                    │
│  8. XChaCha20-Poly1305.encrypt(MK, using RDK) → wrappedMK_R    │
│                                                                  │
│  9. Write to Firestore users/{uid}:                              │
│     {                                                            │
│       crypto: {                                                  │
│         salt: Salt A,                                            │
│         wrappedMasterKey: wrappedMK,                             │
│         recovery: {                                              │
│           salt: Salt B,                                          │
│           wrappedMasterKey: wrappedMK_R                          │
│         }                                                        │
│       }                                                          │
│     }                                                            │
│                                                                  │
│ 10. Hold MK in app memory (VaultNotifier → VaultUnlocked)       │
│ 11. Return recovery phrase to UI for Step 4 display              │
└──────────────────────────────────────────────────────────────────┘
```

Important:
- The **Master Key** is never written to Firestore — only the *wrapped* (encrypted) version is
- The **recovery phrase** is never stored anywhere — shown once, then forgotten by the app
- **Salt A** and **Salt B** are different — they're stored in Firestore so we can re-derive the keys later

---

### Flow 2: Returning User — Vault Unlock (Passphrase)

What the user sees:

```
App opens → Splash → Vault Unlock screen
Enter passphrase → [Loading...] → Home screen
```

What happens behind the scenes:

```
┌───────────────────────────────────────────────────────────────┐
│ User taps "Unlock" with passphrase                            │
│                                                               │
│  1. Fetch crypto metadata from Firestore users/{uid}          │
│     → get salt, wrappedMasterKey, kdfParams                   │
│                                                               │
│  2. Argon2id(passphrase + stored salt) → PDK                  │
│                                                               │
│  3. XChaCha20-Poly1305.decrypt(wrappedMasterKey, using PDK)   │
│     → Master Key                                              │
│                                                               │
│  ✅ Success: MK is valid                                      │
│     → Store MK in memory (VaultNotifier → VaultUnlocked)      │
│     → Navigate to Home                                        │
│                                                               │
│  ❌ Failure: decryption auth tag doesn't match                │
│     → "Incorrect passphrase" error shown                      │
│     → MK stays locked                                         │
└───────────────────────────────────────────────────────────────┘
```

The "magic" here: if you type the wrong passphrase, Argon2id produces a different PDK, and XChaCha20-Poly1305 detects that the decryption is garbage (via its authentication tag). No guessing needed — the algorithm tells us definitively "wrong key."

---

### Flow 3: Vault Unlock with Recovery Phrase

Same as Flow 2, but uses the recovery path:

```
┌───────────────────────────────────────────────────────────────┐
│ User toggles to "Use recovery phrase instead"                 │
│ Types their 12 words                                          │
│                                                               │
│  1. Fetch crypto.recovery metadata from Firestore             │
│     → get recovery salt, recovery wrappedMasterKey            │
│                                                               │
│  2. Argon2id(recovery phrase + recovery salt) → RDK           │
│                                                               │
│  3. XChaCha20-Poly1305.decrypt(recovery wrappedMK, using RDK) │
│     → Master Key                                              │
│                                                               │
│  ✅ Success → VaultUnlocked, navigate to Home                 │
│  ❌ Failure → "Incorrect recovery phrase" error               │
└───────────────────────────────────────────────────────────────┘
```

---

### Flow 4: Logout

What the user sees:

```
Profile tab → "Log Out" button → Back to login screen
```

What happens behind the scenes:

```
┌───────────────────────────────────────────────────────┐
│ User taps "Log Out"                                   │
│                                                       │
│  1. VaultNotifier.lock()                              │
│     → Zero out MK bytes (fill with 0x00)              │
│     → Set state to VaultLocked                        │
│                                                       │
│  2. AuthRepository.signOut()                          │
│     → Firebase sign out                               │
│     → Google sign out (if applicable)                 │
│                                                       │
│  3. Auth state changes → router redirect triggers     │
│     → User sent to login screen                       │
│                                                       │
│  MK is gone from memory. The only way back in is to   │
│  type the passphrase (or recovery phrase) again.       │
└───────────────────────────────────────────────────────┘
```

---

### Flow 5: App Restart (Returning Authenticated User)

```
┌─────────────────────────────────────────────────────────────┐
│ App opens → Splash screen (2s)                              │
│                                                             │
│  Check: Is Firebase user logged in?                         │
│  YES → Navigate to /vault/check                             │
│                                                             │
│  VaultCheckScreen:                                          │
│    Check: Does users/{uid} have 'crypto' field?             │
│    YES → Navigate to /vault/unlock (Flow 2 or 3)            │
│    NO  → Navigate to /sign-up (step 2) for vault setup      │
│                                                             │
│  NO (not logged in) → Onboarding or Login screen            │
└─────────────────────────────────────────────────────────────┘
```

This `VaultCheckScreen` is important because it handles an edge case: what if a user signed up (Firebase account exists) but force-quit the app before completing vault setup? Without this check, they'd be sent to the vault unlock screen with no vault to unlock.

---

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI Layer                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐ │
│  │ SignUpScreen  │  │VaultUnlock   │  │ ProfileScreen          │ │
│  │ (Steps 3-4)  │  │Screen        │  │ (Logout)               │ │
│  └──────┬───────┘  └──────┬───────┘  └───────────┬────────────┘ │
│         │                 │                       │              │
└─────────┼─────────────────┼───────────────────────┼──────────────┘
          │                 │                       │
          v                 v                       v
┌─────────────────────────────────────────────────────────────────┐
│                    State Management Layer                         │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ VaultNotifier (StateNotifier<VaultState>)                   │ │
│  │                                                             │ │
│  │  State: VaultLocked | VaultUnlocked(MK) | VaultSetupReq    │ │
│  │                                                             │ │
│  │  Methods: setup() | unlockWithPassphrase() |                │ │
│  │           unlockWithRecovery() | lock() | resetPassphrase() │ │
│  └──────────────────────────┬──────────────────────────────────┘ │
│                             │                                    │
└─────────────────────────────┼────────────────────────────────────┘
                              │
                              v
┌─────────────────────────────────────────────────────────────────┐
│                      Data Layer                                  │
│  ┌────────────────────────┐    ┌─────────────────────────────┐  │
│  │ VaultRepository        │    │ UserRepository               │  │
│  │                        │    │                              │  │
│  │ Orchestrates crypto    │───>│ getCryptoMetadata(uid)       │  │
│  │ + Firestore writes     │    │ hasVaultSetup(uid)           │  │
│  └───────────┬────────────┘    └──────────────────────────────┘  │
│              │                                                    │
└──────────────┼────────────────────────────────────────────────────┘
               │
               v
┌─────────────────────────────────────────────────────────────────┐
│                    Crypto Layer                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ CryptoService (pure functions, no state, no Firestore)      │ │
│  │                                                             │ │
│  │  generateMasterKey()     → 32 random bytes                  │ │
│  │  generateSalt()          → 16 random bytes                  │ │
│  │  deriveKey()             → Argon2id                         │ │
│  │  wrapKey()               → XChaCha20-Poly1305 encrypt       │ │
│  │  unwrapKey()             → XChaCha20-Poly1305 decrypt       │ │
│  │  generateRecoveryPhrase()→ 12 BIP39 words                  │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Firestore Data Structure

### What gets stored in `users/{uid}`

```
users/
  abc123/
    recentDocumentViews: []
    createdAt: <timestamp>
    updatedAt: <timestamp>
    crypto:                              ← Added during vault setup
      kdf: "argon2id"                    ← Which algorithm derived the key
      kdfParams:                         ← How hard to make the derivation
        m: 65536                         ← 64MB memory
        t: 3                             ← 3 iterations
        p: 1                             ← 1 thread
      salt: "a3Bf9x..."                 ← Random bytes (base64), stored so we
                                            can re-derive the same key later
      wrappedMasterKey: "nK8mP2..."     ← The Master Key, encrypted with PDK
                                            (base64: nonce + ciphertext + mac)
      cipher: "xchacha20-poly1305"       ← Which algorithm encrypted the MK
      keyVersion: 1                      ← For future key rotation
      recovery:                          ← Recovery phrase unlock path
        kdf: "argon2id"
        kdfParams:
          m: 65536
          t: 3
          p: 1
        salt: "x7Kp3m..."              ← DIFFERENT salt from passphrase!
        wrappedMasterKey: "qR5tY8..."  ← Same MK, but encrypted with RDK
        cipher: "xchacha20-poly1305"
        enabled: true
```

### What is NOT stored anywhere

| Secret | Where it lives | Lifetime |
|--------|---------------|----------|
| Vault passphrase | User's brain | Forever (user memorizes it) |
| Recovery phrase | User's written backup | Shown once during setup, then gone |
| Master Key (MK) | App memory only | While app is open and vault is unlocked |
| PDK (password-derived key) | Nowhere — recomputed each time | Only during unlock computation |
| RDK (recovery-derived key) | Nowhere — recomputed each time | Only during recovery computation |

---

## Security — Who Can See What?

```
                    Can see          Can see          Can decrypt
                    metadata?        encrypted MK?    files?
                    ─────────        ─────────────    ──────────
Firebase admin      ✅ Yes           ✅ Yes            ❌ No
App developer       ✅ Yes           ✅ Yes            ❌ No
Someone with        ❌ No            ❌ No             ❌ No
  network access
User with           ✅ Yes           ✅ Yes            ✅ Yes
  passphrase
User with           ✅ Yes           ✅ Yes            ✅ Yes
  recovery phrase
```

Even if someone steals the entire Firestore database, they get:
- Encrypted blobs they can't decrypt
- Salt values (useless without the passphrase)
- KDF parameters (public knowledge, not secret)

They would still need to brute-force the passphrase through Argon2id (64MB RAM x 3 iterations per guess), which is computationally infeasible for a strong passphrase.

---

## Edge Cases and Error Handling

| Scenario | What happens |
|----------|-------------|
| Wrong passphrase | XChaCha20-Poly1305 auth tag fails → "Incorrect passphrase" error |
| Wrong recovery phrase | Same as above → "Incorrect recovery phrase" error |
| User force-quits during vault setup | Firebase account exists but no `crypto` field → VaultCheckScreen detects this and sends user back to vault setup steps |
| App crashes while unlocked | MK lost from memory → user must re-enter passphrase on next launch |
| User changes passphrase | New salt + PDK computed, MK re-wrapped. Recovery phrase stays valid (it wraps the same MK with a separate key) |
| Argon2id slow on device | Expected: 1-3 seconds on mobile. UI shows loading spinner. Acceptable tradeoff for security |

---

## File Map

| File | Layer | Purpose |
|------|-------|---------|
| `lib/core/constants/bip39_english.dart` | Constants | 2048-word list |
| `lib/core/services/crypto_service.dart` | Crypto | Pure crypto primitives |
| `lib/features/vault/data/vault_repository.dart` | Data | Crypto + Firestore orchestration |
| `lib/features/vault/domain/vault_provider.dart` | Domain | State management (VaultNotifier) |
| `lib/features/vault/presentation/vault_check_screen.dart` | UI | Vault status routing |
| `lib/features/auth/presentation/vault_unlock_screen.dart` | UI | Unlock form (passphrase or recovery) |
| `lib/features/auth/presentation/sign_up_screen.dart` | UI | Sign-up flow (steps 3-4 trigger crypto) |
| `lib/features/auth/data/user_repository.dart` | Data | Firestore user doc access |
| `lib/app/router.dart` | Routing | Auth + vault guards |
