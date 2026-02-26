
# 🔐 Feature 1 — Authentication + Vault Setup + Unlock + Recovery (Zero-Knowledge Ready)

This feature defines:

* Firebase Authentication
* User initialization in Firestore
* Vault passphrase setup
* Recovery phrase/code setup (one-time)
* Key derivation + master key wrapping
* Vault unlock flow (passphrase or recovery)
* Session behavior
* Logout behavior
* Security guarantees

This feature must be completed before Feature 1 works.

---

# 🎯 Feature 2 Scope

Feature 2 is responsible for:

1. Authenticating the user (Firebase Auth)
2. Creating the user profile doc in Firestore
3. Setting up encryption (first login only)
4. Providing a one-time Recovery Phrase/Code
5. Unlocking vault on subsequent logins
6. Keeping the master key in memory only
7. Clearing sensitive data on logout

---

# 1️⃣ Firebase Authentication

## Supported Login Methods (MVP)

* Google Sign-In
* Apple Sign-In (optional)
* Email/Password (optional)

### Zero-knowledge requirement

Even if using Google/Apple sign-in, user MUST create a separate:

> Vault Passphrase/PIN

This secret is never stored server-side and is required for encryption.

---

# 2️⃣ First Login Flow (User Initialization)

## Step 1 — Firebase Auth Login

User signs in.

Check:

```text
users/{uid} exists?
```

---

## Step 2 — If User Doc Does Not Exist

Create:

`users/{uid}`

```json
{
  "recentDocumentViews": [],
  "createdAt": "serverTimestamp()",
  "updatedAt": "serverTimestamp()"
}
```

Then proceed to Vault Setup.

---

# 3️⃣ Vault Setup (First-Time Encryption Initialization)

This happens only once per user.

---

## 🔐 Vault Setup Screen (UI)

UI Requirements:

* Title: “Secure Your Vault”
* Input: Create Vault Passphrase/PIN
* Confirm passphrase
* Warning (must be visible):

  > “If you forget this passphrase, we cannot recover your files unless you saved your recovery phrase.”

After successful setup:

* Show “Your Recovery Phrase” screen (one-time view)

---

## 🔑 Vault Setup Technical Flow

### Step 1 — Generate crypto materials

Generate:

* 32-byte random Master Key (MK)
* 16–32 byte random salt (for KDF)

### Step 2 — Derive Password-Derived Key (PDK)

Using:

* Argon2id
* salt
* parameters (store these)

Example parameters:

```json
{ "m": 65536, "t": 3, "p": 1 }
```

PDK = Argon2id(passphrase, salt, params)

### Step 3 — Wrap Master Key with PDK

```text
wrappedMasterKey = Encrypt(MK, PDK)
```

Use AES-256-GCM or XChaCha20-Poly1305.

---

# 4️⃣ Recovery Phrase / Code (One-time)

## Goal

Allow users to regain access if they forget their passphrase, without breaking zero-knowledge.

The recovery phrase is shown **once**, and the app never stores it in plaintext.

---

## Recovery Screen (UI)

After vault setup:

* Show a generated recovery phrase/code
* “Copy” button
* “I saved it” confirmation checkbox (must be checked to continue)
* Warning:

  > “We cannot recover this for you. Store it safely.”

---

## Recovery Technical Flow

### Step 1 — Generate Recovery Phrase

MVP simple options (choose one):

* **Option A (recommended)**: 12-word phrase generated securely (like “wordlist” style)
* **Option B**: 32-byte base64 recovery code

Either is fine for MVP as long as it is cryptographically random.

Let’s use a simple and reliable approach:

* Generate `recoveryKey` = random 32 bytes
* Display to user as base64 OR as 12-word phrase derived from entropy

### Step 2 — Derive Recovery Derived Key (RDK)

Use Argon2id again:

RDK = Argon2id(recoveryPhrase, recoverySalt, recoveryParams)

### Step 3 — Wrap Master Key with Recovery Key

```text
wrappedMasterKeyRecovery = Encrypt(MK, RDK)
```

### Step 4 — Store recovery metadata in Firestore

Update `users/{uid}` with:

```json
{
  "crypto": {
    "kdf": "argon2id",
    "kdfParams": { "m": 65536, "t": 3, "p": 1 },
    "salt": "base64...",
    "wrappedMasterKey": "base64...",
    "keyVersion": 1,

    "recovery": {
      "kdf": "argon2id",
      "kdfParams": { "m": 65536, "t": 3, "p": 1 },
      "salt": "base64...",
      "wrappedMasterKey": "base64...",
      "enabled": true
    }
  },
  "updatedAt": "serverTimestamp()"
}
```

Important:

* Do NOT store recovery phrase in plaintext
* Do NOT store MK in plaintext

### Step 5 — Master Key in memory only

After setup:

* Store MK in memory only for the session
* Do not write MK to disk

---

# 5️⃣ Subsequent Login Flow (Vault Unlock)

On login:

1. Fetch `users/{uid}`
2. If `crypto` missing → run Vault Setup
3. If `crypto` exists → show Vault Unlock screen

---

## 🔓 Vault Unlock Screen (UI)

Two unlock methods:

1. Unlock with Vault Passphrase/PIN
2. Unlock with Recovery Phrase/Code (“Use recovery instead”)

---

## Unlock Method A — Passphrase

### Step 1

Derive PDK using stored `salt` + `kdfParams`

### Step 2

Decrypt wrappedMasterKey → MK

If incorrect:

* show “Incorrect passphrase”

If correct:

* store MK in memory
* continue to app

---

## Unlock Method B — Recovery Phrase/Code

### Step 1

Derive RDK using stored recovery salt + recovery kdfParams

### Step 2

Decrypt `crypto.recovery.wrappedMasterKey` → MK

If incorrect:

* show “Incorrect recovery phrase”

If correct:

* store MK in memory
* allow user to set a NEW vault passphrase (recommended UX)

### Optional UX (recommended)

After recovery unlock:

* force “Reset Vault Passphrase”

  * user sets a new passphrase
  * derive new PDK
  * re-wrap MK
  * update `wrappedMasterKey`
* recovery key remains valid unless user regenerates it (future)

---

# 6️⃣ Master Key Lifecycle

MK exists only:

* in memory
* during unlocked session

Never:

* in Firestore as plaintext
* in Storage as plaintext
* in logs
* in crash reports
* in SharedPreferences

---

# 7️⃣ Session Behavior

Vault stays unlocked until:

* user logs out
* app restarts
* optional inactivity timeout (future feature)

---

# 8️⃣ Logout Flow

On logout:

1. Clear MK from memory
2. Clear any decrypted buffers/caches
3. FirebaseAuth.signOut()
4. Return to login screen

---

# 9️⃣ Security Guarantees

✅ Admin can see Firestore metadata
✅ Admin can see encrypted blobs (ciphertext)
❌ Admin cannot decrypt files
❌ Firebase cannot decrypt files
❌ Developer cannot decrypt without passphrase or recovery phrase

---

# 🔟 Error Handling Requirements

* If user doc missing crypto → force setup
* If wrappedMasterKey corrupted → recovery unlock still possible
* If both keys corrupted → vault cannot be opened (show “vault data corrupted”)
* Throttle repeated unlock failures

---

# 11️⃣ Firestore Rules (Feature 2 Scope)

Users collection must be owner-only:

```javascript
match /users/{userId} {
  allow read, create, update, delete: if request.auth != null
    && request.auth.uid == userId;
}
```

---

# 12️⃣ Acceptance Criteria (Feature 2 Complete When)

* User can authenticate via Firebase
* First login triggers vault setup
* Passphrase-based encryption is configured:

  * salt + kdfParams + wrappedMasterKey stored
* Recovery phrase is generated and shown once
* Recovery wrapper is stored:

  * recovery.salt + recovery.kdfParams + recovery.wrappedMasterKey
* User can unlock vault using:

  * passphrase OR recovery phrase
* After recovery unlock, user can reset passphrase
* Master key is stored only in memory
* Logout clears sensitive data
