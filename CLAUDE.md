# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DocVault (also referred to as "DocuFind") is a secure document vault and application package checklist app built with Flutter. Users upload and organize personal documents with zero-knowledge encryption, create application packages from templates, and track document expiry. The app targets iOS, Android, macOS, Linux, Web, and Windows.

**Current state:** Early development — the codebase contains the default Flutter counter app scaffold (`lib/main.dart`). No Firebase, Riverpod, or go_router dependencies added yet. Feature specs are in `specs/`.

## Build & Run Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run on connected device/emulator
flutter run -d chrome        # Run on web
flutter run -d macos          # Run on macOS
flutter test                 # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze              # Run static analysis (uses flutter_lints)
flutter build apk            # Build Android APK
flutter build ios            # Build iOS
```

## Tech Stack

- **Framework:** Flutter (Dart SDK ^3.10.7)
- **Backend:** Firebase (Auth, Cloud Firestore, Firebase Storage)
- **State management:** Riverpod (planned, not yet added)
- **Routing:** go_router (planned, not yet added)
- **UI:** Material 3 with centralized theming
- **Linting:** `flutter_lints` via `analysis_options.yaml`

## Architecture (Planned)

```
lib/
  core/          # Constants, theme, crypto utilities, shared config
  models/        # Data classes for Firestore documents
  repositories/  # Firestore/Storage data access layer
  services/      # Business logic (encryption, auth, auto-complete)
  features/      # Feature-based UI screens and widgets
  widgets/       # Shared reusable widgets
```

## Key Architectural Concepts

### Zero-Knowledge Encryption
All uploaded files are encrypted client-side before reaching Firebase Storage. The server stores only ciphertext. Key hierarchy: Vault Passphrase → PDK (Argon2id) → Master Key (AES-256-GCM or XChaCha20-Poly1305 wrapped) → per-file File Keys. The Master Key only exists in memory during an unlocked session.

### Firestore Data Model
- `users/{uid}` — profile, recent views, crypto metadata, entitlements, usage counters
- `documents/{documentId}` — logical documents owned by a user (title, category, subcategory, country, dates)
- `documents/{documentId}/files/{fileId}` — encrypted file metadata (storagePath, crypto params)
- `packages/{packageId}` — application packages (manual or template-based)
- `packages/{packageId}/tasks/{taskId}` — checklist tasks with auto-matching via `expectedSubcategoryId`
- `templates/{templateId}` — system-defined read-only templates
- `templates/{templateId}/tasks/{taskId}` — template task definitions
- `categories/{categoryId}` and `subcategories/{subcategoryId}` — taxonomy

### Auto-Complete Matching
When a document is uploaded or a package is created, tasks are auto-completed when `task.expectedSubcategoryId == document.subcategoryId`. Country is not part of matching in MVP.

### Security Model
- Templates: public read-only, no user writes
- All user data (documents, files, packages): owner-only access via Firestore rules
- Storage paths: `users/{uid}/documents/{documentId}/files/{fileId}.bin`
- Content-type for all stored files: `application/octet-stream`

## Feature Specs

Overall product and technical spec: `specs/initial-requirements.md`

Individual feature specs in `specs/`:
- Feature 1: Authentication + Vault Setup + Unlock + Recovery (`specs/Feature 1: Authentication/`)
- Feature 2: Document Upload with CRUD + Encryption (`specs/Feature 2: Document Upload/`)
- Feature 3: Application Template/Package System (`specs/Feature 3: Application Template/`)
- Feature 4: Expiring document notifications (`specs/Feature 4: Notification for expiring documents/`)
- Feature 5: Premium tier architecture (`specs/Feature 5: Premium pricing/`)
- Feature 6: AI-powered template updates (spec not yet written)

Feature 1 spec directory also contains UI mockup screenshots for onboarding, sign-up, sign-in, and password reset flows.

## Conventions

- Material 3 theming with no hardcoded colors; use 8/16/24 spacing
- Package tasks are snapshots copied from templates at creation time — template updates do not retroactively affect existing packages
- Decrypted data must never be persisted to disk, logs, crash reports, or SharedPreferences
- Firestore counters (`fileCount`, `totalSizeBytes`) are updated transactionally on upload/delete

## Flutter Code Style

### Naming
- Files: `snake_case.dart` (e.g. `user_profile_screen.dart`, `auth_service.dart`)
- Classes: `PascalCase` (e.g. `UserProfileScreen`)
- Variables/methods: `camelCase` (e.g. `fetchUserData()`)

### Architecture per Feature
Each feature follows clean architecture layers:
```
features/
  auth/
    data/           # API calls, repositories impl
    domain/         # Business logic, entities
    presentation/   # Screens, widgets, controllers
```
Separate UI, business logic, and data access — no business logic in widgets.

### Widget Rules
- Use `const` constructors wherever possible (`const Text('Hello')`, `const SizedBox(height: 16)`)
- Extract widgets when they exceed ~50 lines
- Avoid deep widget nesting — extract into named widget classes
- Use `ListView.builder` instead of `ListView` for dynamic lists

### State Management
Use Riverpod — never use `setState` for business logic:
```dart
// Good: ref.read(counterProvider.notifier).increment();
// Bad: setState(() { counter++; });
```

### Theming & Layout
- Use `Theme.of(context).textTheme.*` and `Theme.of(context).colorScheme.*` — never hardcode colors or text styles
- Use `Expanded`, `Flexible`, `Spacer` for layouts — avoid hardcoded widths/heights
- Rounded cards for content containers

### Logging
Use `dart:developer` `log()` — never `print()` or `debugPrint()`.

### Formatting
- Run `dart format .` before committing
- Max line length: 80–100 characters

### Testing Structure
```
test/
  widget/        # Widget tests
  unit/          # Unit tests
  integration/   # Integration tests
```
