```
APP_SPEC.md
```

---

# 📄 DocuFind MVP – Product & Technical Specification

---

## 🎯 Product Vision

DocuFind is a secure document vault + application package checklist app.

Users can:

* Upload and organize personal documents
* Create application packages manually or from predefined templates
* Automatically complete checklist tasks when documents exist
* View recently accessed documents
* Browse global immigration templates
* Store files with zero-knowledge encryption (admin cannot view contents)

---

# 🧱 Core Architecture

## Tech Stack

* Flutter (stable)
* Firebase Auth
* Cloud Firestore
* Firebase Storage
* Riverpod (state management)
* go_router (routing)
* Material 3 UI

---

# 🔐 Zero-Knowledge Encryption (Client-Side Encryption)

## Overview

All uploaded files MUST be encrypted on-device before being uploaded to Firebase Storage.

Firebase Storage stores **only encrypted bytes (ciphertext)**.

Admins can see metadata such as:

* User has uploaded a passport (via `subcategoryId`)
* File count
* File sizes

Admins CANNOT:

* View file contents
* Decrypt files
* Access encryption keys

---

## Key Hierarchy

* **Vault Passphrase/PIN** (user secret, never stored)
* **PDK (Password-Derived Key)** → derived using Argon2id
* **Master Key (MK)** → randomly generated per user
* **File Key (FK)** → randomly generated per file

### Flow

### 1️⃣ Vault Setup (First Login)

1. User signs in via Firebase Auth
2. If no crypto setup:

   * User sets Vault Passphrase/PIN
   * App generates:

     * random 32-byte Master Key (MK)
     * random salt
   * Derive PDK = Argon2id(passphrase, salt)
   * Encrypt MK with PDK → `wrappedMasterKey`
   * Store only:

     * `salt`
     * `kdfParams`
     * `wrappedMasterKey`

Passphrase is NEVER stored.

---

### 2️⃣ File Upload Encryption Flow

1. Generate random File Key (FK)
2. Encrypt file bytes with FK (XChaCha20-Poly1305 preferred)
3. Encrypt FK with MK → `wrappedFileKey`
4. Upload encrypted bytes to Firebase Storage
5. Store encryption metadata in Firestore

---

### 3️⃣ File Decryption Flow

1. User unlocks vault (enter passphrase)
2. Derive PDK
3. Decrypt wrappedMasterKey → MK
4. Decrypt wrappedFileKey → FK
5. Decrypt file locally
6. Display decrypted content in-app only

Decrypted data must not be stored persistently.

---

## Account Recovery

* If user forgets vault passphrase → files are unrecoverable.
* Show one-time Recovery Key during setup.

---


# ⚙️ Feature 1 — Document Upload


---

# ⚙️ Feature 2 — Auto Task Completion


---

# ⚙️ Feature 3 — Recently Viewed


---

# 📱 UI Structure

## Bottom Navigation

* Documents
* Packages
* Templates

---

## Documents Screen

* Recently Viewed
* All Documents
* FAB: Create Document

---

## Document Detail

* Metadata
* Files list
* Upload button
* Vault unlock required for preview

---

## Packages Screen

* List packages
* Progress indicator
* FAB: Create Package

---

## Create Package Flow

* Manual
* From Template

---

## Package Detail

* Grouped tasks
* Checkboxes
* Manual task addition

---

# 🎨 Theming

* Material 3
* Centralized theme
* No hardcoded colors
* 8/16/24 spacing
* Rounded cards

---

# 🗂 Folder Structure

```
lib/
  core/
  models/
  repositories/
  services/
  features/
  widgets/
```

---

# 🔐 Security

* Templates: public read-only
* Users: own doc only
* Documents: owner-only
* Files: owner-only
* Packages: owner-only

---

# 🚀 MVP Deliverables

* Auth
* Vault setup + unlock
* Encrypted file upload
* Recently viewed
* Manual + template packages
* Auto-complete tasks
* Secure Firestore rules

---

# 🏁 End State

A secure, scalable, zero-knowledge document vault + application checklist app that:

* Supports global templates
* Auto-matches documents
* Protects user files from admin access
* Requires no schema redesign later

---
# Code Style And industry standard

Here is an **industry-standard Flutter code style guide**, similar in spirit to the image you shared, but expanded to reflect best practices used in professional Flutter teams.

---

# Flutter Code Style Guide (Industry Standard)

## 1. Project Structure & Separation of Concerns

* Follow **feature-based or layered architecture**.

Example feature-based structure:

```
lib/
│
├── main.dart
├── app/
│   ├── app.dart
│   ├── routes.dart
│   └── theme.dart
│
├── core/
│   ├── constants/
│   ├── utils/
│   ├── services/
│   └── widgets/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── home/
│       ├── data/
│       ├── domain/
│       └── presentation/
```

Best practices:

* Separate:

  * UI (presentation)
  * Business logic (controllers, providers, bloc, etc.)
  * Data layer (API, database)
* Avoid putting everything in `main.dart`

---

## 2. File Naming Conventions

Use **snake_case** for files:

```
user_profile_screen.dart
auth_service.dart
custom_button.dart
```

Use **PascalCase** for classes:

```
class UserProfileScreen extends StatelessWidget {}
```

Use **camelCase** for variables and methods:

```
final userName = 'Patrick';

void fetchUserData() {}
```

---

## 3. Widget Best Practices

### Prefer small, reusable widgets

❌ Bad:

```
Widget build(BuildContext context) {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.all(16),
        child: Text("Hello"),
      ),
    ],
  );
}
```

✅ Good:

```
Widget build(BuildContext context) {
  return const GreetingText();
}

class GreetingText extends StatelessWidget {
  const GreetingText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text("Hello"),
    );
  }
}
```

Rule:

* If widget > 50 lines → extract it

---

## 4. Use const Wherever Possible

Improves performance.

✅ Good:

```
const Text('Hello');
const SizedBox(height: 16);
```

❌ Bad:

```
Text('Hello');
SizedBox(height: 16);
```

---

## 5. State Management Separation

Do NOT mix UI and business logic.

❌ Bad:

```
onPressed: () {
  setState(() {
    counter++;
  });
}
```

✅ Good:
Use Provider, Riverpod, Bloc, or Controller:

```
ref.read(counterProvider.notifier).increment();
```

Industry standard choices:

* Riverpod (modern standard)
* Bloc (enterprise standard)
* Provider (simple apps)

---

## 6. Layout Best Practices

Use flexible layouts.

Prefer:

```
Expanded()
Flexible()
Spacer()
```

Avoid hardcoded sizes:

```
Container(width: 300) ❌
```

Prefer:

```
Expanded(child: Container()) ✅
```

---

## 7. Constants & Theming

Avoid hardcoding values.

❌ Bad:

```
Text(
  'Hello',
  style: TextStyle(fontSize: 18, color: Colors.blue),
)
```

✅ Good:

```
Text(
  'Hello',
  style: Theme.of(context).textTheme.titleMedium,
)
```

Use constants:

```
class AppColors {
  static const primary = Color(0xFF0066FF);
}
```

---

## 8. Logging Best Practice

Use:

```
import 'dart:developer';

log('User logged in');
```

Avoid:

```
print('User logged in');
debugPrint('User logged in');
```

---

## 9. Async & Future Handling

Always use async/await cleanly.

✅ Good:

```
Future<void> fetchUser() async {
  try {
    final user = await api.getUser();
  } catch (e) {
    log(e.toString());
  }
}
```

---

## 10. Null Safety

Always use null safety properly.

```
String? name;
String name = '';
late String name;
```

Avoid force unwrap unless necessary:

```
name! ❌
```

---

## 11. Code Formatting Rules

Use official formatter:

```
dart format .
```

Max line length:

```
80–100 characters
```

---

## 12. Linting (Required in industry)

Add to `pubspec.yaml`:

```
dev_dependencies:
  flutter_lints: ^3.0.0
```

or stronger:

```
very_good_analysis
```

---

## 13. Performance Best Practices

Use:

* const widgets
* ListView.builder instead of ListView
* Avoid unnecessary rebuilds
* Use Keys properly

Example:

```
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(item: items[index]);
  },
)
```

---

## 14. Avoid Deep Widget Nesting

❌ Bad:

```
Container(
  child: Column(
    child: Row(
```

✅ Good:
Extract widgets.

---

## 15. Commenting Guidelines

Explain WHY, not WHAT.

Good:

```
/// Handles authentication token refresh automatically
Future<void> refreshToken() {}
```

Avoid useless comments:

```
/// This is a function
```

---

## 16. Recommended Architecture (Industry Standard)

Most modern Flutter companies use:

Feature-based + Clean Architecture + Riverpod

Example:

```
features/
 ├── auth/
 │   ├── presentation/
 │   ├── domain/
 │   └── data/
```

---

## 17. Testing Structure

```
test/
 ├── widget/
 ├── unit/
 └── integration/
```

---

# Summary Checklist (Quick Reference)

✔ Separate UI, logic, and data
✔ Use feature-based folder structure
✔ Use small reusable widgets
✔ Use const whenever possible
✔ Avoid hardcoded sizes/colors
✔ Use Theme and constants
✔ Use proper state management (Riverpod/Bloc)
✔ Use dart:developer log instead of print
✔ Follow snake_case for files, PascalCase for classes
✔ Use lint rules and formatter
