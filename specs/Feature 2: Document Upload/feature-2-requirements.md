# ⚙️ Feature 2 — Document Upload (Vault) with CRUD + Encryption + Country + Dates

This feature defines the complete **Document Vault** system:

* Create / Read / Update / Delete logical documents
* Upload / list / delete encrypted files
* Store country of issuance
* Store issue & expiry dates
* Maintain recently viewed (last 5)
* Trigger task auto-complete hook

---

# 1️⃣ Data Model Used

## Firestore Structure

### Logical Document

`documents/{documentId}`

```json
{
  "ownerId": "uid",
  "title": "Passport",
  "categoryId": "identity_documents",
  "subcategoryId": "passport",

  "countryCode": "CA",
  "countryName": "Canada",

  "status": "active",

  "dates": {
    "issuedAt": "Timestamp|null",
    "expiresAt": "Timestamp|null"
  },

  "fileCount": 0,
  "totalSizeBytes": 0,

  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

---

### Files Under a Document

`documents/{documentId}/files/{fileId}`

```json
{
  "storagePath": "users/{uid}/documents/{documentId}/files/{fileId}.bin",
  "originalNameEncrypted": "base64...",
  "mimeType": "application/octet-stream",
  "sizeBytes": 1234567,
  "crypto": {
    "alg": "xchacha20poly1305",
    "nonce": "base64...",
    "wrappedFileKey": "base64..."
  },
  "createdAt": "Timestamp"
}
```

---

### Recently Viewed

`users/{uid}`

```json
{
  "recentDocumentViews": [
    { "documentId": "doc_1", "viewedAt": "Timestamp" }
  ],
  "crypto": {
    "kdf": "argon2id",
    "kdfParams": { "m": 65536, "t": 3, "p": 1 },
    "salt": "base64...",
    "wrappedMasterKey": "base64...",
    "keyVersion": 1
  },
  "updatedAt": "Timestamp"
}
```

---

### Firebase Storage Path

Encrypted file blobs only:

```text
users/{uid}/documents/{documentId}/files/{fileId}.bin
```

Storage content-type must be:

```
application/octet-stream
```

---

# 2️⃣ UX Screens & Flows

---

## A) Documents List Screen

### Purpose

Shows user's entire document vault.

### Sections

1. Recently Viewed (max 5)
2. All Documents (sorted by updatedAt desc)

### Each Document Card Displays

* Title
* Country of issuance
* Expiry date (if present)
* File count
* Updated date

Example:

```
Passport
Canada 🇨🇦
Expires: 2029-03-10
1 file
```

### FAB

Create Document

---

## B) Create Document (CRUD — Create)

### Inputs

* Title (required)
* Category (required)
* Subcategory (required)
* Country of Issuance (required)
* Issue Date (optional)
* Expiry Date (optional)

### Validation

* If both dates exist → expiry must be after issue
* Null values allowed

### Firestore Write

Create `documents/{documentId}`:

* ownerId = auth.uid
* status = "active"
* fileCount = 0
* totalSizeBytes = 0
* createdAt / updatedAt = serverTimestamp()

### After Create

Navigate to Document Detail.

---

## C) Document Detail (CRUD — Read)

Displays:

* Title
* Category
* Subcategory
* Country of Issuance
* Issue Date
* Expiry Date
* File Count
* Total Size
* File list

### File Row Shows

* Decrypted filename (if vault unlocked)
* File size
* View button
* Delete button

### On Open

Update recently viewed:

* Remove existing entry
* Insert at front
* Keep max 5

---

## D) Edit Document (CRUD — Update)

Editable Fields:

* Title
* Category
* Subcategory
* Country
* Issue Date
* Expiry Date
* Status (active/archived)

### Firestore Update

Update only editable fields.
Set updatedAt = serverTimestamp().

### Subcategory Change Behavior

MVP:

* Do NOT auto-uncomplete tasks.
* Keep logic predictable and non-destructive.

---

## E) Delete Document (CRUD — Delete)

### Confirmation Required

"This will permanently delete this document and all files."

### Client-Driven Delete (MVP)

1. Query all file subdocs
2. For each:

   * Delete Storage blob
   * Delete file subdoc
3. Delete parent document

### Task Impact

* Do not auto-mark tasks incomplete.
* If task links to deleted doc → show “Document missing” in UI.

---

# 3️⃣ Encrypted File Upload

---

## Preconditions

* Vault must be unlocked.
* Master Key (MK) available in memory only.

If vault locked:

* Disable upload
* Show “Unlock vault to upload”

---

## Upload Flow

1. User selects file
2. Read file bytes
3. Generate:

   * File Key (FK) — 32 bytes random
   * Nonce — random
4. Encrypt file locally:

   * ciphertext = Encrypt(fileBytes, FK, nonce)
5. Wrap file key:

   * wrappedFileKey = Encrypt(FK, MK)
6. Upload ciphertext to Storage
7. Create file subdocument in Firestore
8. Update parent document counters in transaction:

   * fileCount += 1
   * totalSizeBytes += sizeBytes
   * updatedAt = serverTimestamp()
9. Trigger auto-complete hook

---

## Failure Handling Rules

* If encryption fails → abort.
* If upload fails → do not create Firestore file doc.
* If Firestore write fails → delete uploaded blob.
* Always show upload progress.

---

# 4️⃣ File View (Encrypted Read)

---

## Steps

1. Ensure vault unlocked
2. Fetch file subdoc
3. Download ciphertext
4. Unwrap FK using MK
5. Decrypt locally
6. Display in viewer
7. Clear decrypted buffers when leaving

No plaintext ever stored in Firebase.

---

# 5️⃣ Delete Individual File

---

## Steps

1. Delete Storage blob
2. Delete file subdoc
3. Update counters:

   * fileCount -= 1
   * totalSizeBytes -= sizeBytes
   * updatedAt = serverTimestamp()

### Task Behavior

* Do not auto-uncomplete tasks (MVP).

---

# 6️⃣ Auto-Complete Hook (Integration with Feature 3)

After successful file upload:

Find tasks where:

```
task.expectedSubcategoryId == document.subcategoryId
AND task.status == "missing"
AND package.ownerId == auth.uid
```

Update:

```
task.status = "complete"
task.documentId = documentId
```

Country is NOT part of matching in MVP.

---

# 7️⃣ Recently Viewed Logic

On Document Detail open:

1. Read users/{uid}
2. Remove existing entry if present
3. Insert at front
4. Trim to 5
5. Update updatedAt

---

# 8️⃣ Security Scope

## Firestore Rules

* documents/* owner-only
* files subcollection owner-only
* users/{uid} owner-only

## Storage Rules

Only allow:

```
auth.uid == path userId
```

Admins can see ciphertext but cannot decrypt.

---

# 9️⃣ Status Values

Recommended:

* active
* archived

Archive hides document without deleting files.

---

# 🔟 Acceptance Criteria (Feature 1 Complete When)

* User can create document with:

  * Category
  * Subcategory
  * Country
  * Issue date
  * Expiry date
* User can edit these fields
* User can delete document
* User can upload multiple encrypted files
* Files are encrypted in Storage
* Counters update correctly
* Recently viewed works
* Upload triggers auto-complete attempt
