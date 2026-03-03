# Plan: Add Structured Logging with Talker

## Context
The app has 22 `dart:developer` `log()` calls across auth repository, screens, and profile. These logs only appear in the terminal. The user wants structured logging with an in-app log viewer for easier debugging, especially on physical devices. We'll integrate the [talker](https://pub.dev/packages/talker) + [talker_flutter](https://pub.dev/packages/talker_flutter) packages.

## What Talker provides
- Structured log levels: `info()`, `warning()`, `debug()`, `error()`, `handle()` (for exceptions with stack traces)
- In-app `TalkerScreen` widget to view logs on-device
- `TalkerRouteObserver` for automatic route change logging
- Color-coded, searchable, filterable log history

## Changes

### 1. Add dependencies to `pubspec.yaml`
- `talker: ^4.0.0`
- `talker_flutter: ^4.0.0`

### 2. Create `lib/core/services/logger_service.dart`
- Initialize a singleton `Talker` instance
- Expose a Riverpod provider: `final talkerProvider = Provider<Talker>((ref) => appTalker);`
- Wrap `main()` in `runZonedGuarded` to catch uncaught exceptions

### 3. Update `lib/main.dart`
- Import and initialize talker before `runApp`
- Wrap `runApp` in `runZonedGuarded` with `talker.handle()` for uncaught errors

### 4. Update `lib/app/app.dart`
- Add `TalkerRouteObserver` to `MaterialApp.router` via `routerConfig`'s `observers` — actually GoRouter doesn't support observers directly the same way. Instead, we'll add it to `GoRouter(observers: [TalkerRouteObserver(talker)])` in `router.dart`.

### 5. Update `lib/app/router.dart`
- Add `observers: [TalkerRouteObserver(talkerProvider)]` to the `GoRouter` constructor so route changes are logged automatically.
- The provider will need to accept the `Talker` instance. We'll pass it via `ref.read(talkerProvider)`.

### 6. Replace all `dart:developer` `log()` calls with `talker` calls
Files to update (8 files):
- `lib/features/auth/data/auth_repository.dart` — 11 log calls → `talker.info()` / `talker.error()`
- `lib/features/auth/data/user_repository.dart` — 1 log call
- `lib/features/auth/presentation/login_or_signup_screen.dart` — 2 log calls
- `lib/features/auth/presentation/sign_in_screen.dart` — 4 log calls
- `lib/features/auth/presentation/sign_up_screen.dart` — 2 log calls
- `lib/features/auth/presentation/forgot_password_email_screen.dart` — 1 log call
- `lib/features/home/presentation/profile_screen.dart` — 1 log call

**Approach for repositories** (no Riverpod access): Accept `Talker` via constructor injection, just like they already accept optional `FirebaseAuth`/`GoogleSignIn`/`FirebaseFirestore`.

**Approach for screens** (have `ref`): Use `ref.read(talkerProvider)` in event handlers.

### 7. Add TalkerScreen route to dev menu
- Add a route `/dev/logs` in `router.dart` (debug only, like dev menu)
- Add a "View Logs" button to `lib/core/widgets/dev_menu_screen.dart`
- Or simpler: add a debug FAB on the home shell that opens `TalkerScreen` — accessible from anywhere in debug mode.

**Recommended:** Add to dev menu as a navigation item + add a long-press gesture on the app title or a debug FAB on home shell.

### 8. Update `lib/features/auth/domain/auth_provider.dart`
- Update `authRepositoryProvider` and `userRepositoryProvider` to pass `ref.read(talkerProvider)` to their constructors.

## Files modified
1. `pubspec.yaml` — add 2 packages
2. `lib/core/services/logger_service.dart` — **new file**, talker init + provider
3. `lib/main.dart` — runZonedGuarded + talker init
4. `lib/app/app.dart` — no change needed (router handles observers)
5. `lib/app/router.dart` — add TalkerRouteObserver
6. `lib/features/auth/domain/auth_provider.dart` — pass talker to repos
7. `lib/features/auth/data/auth_repository.dart` — replace log() with talker
8. `lib/features/auth/data/user_repository.dart` — replace log() with talker
9. `lib/features/auth/presentation/login_or_signup_screen.dart` — replace log()
10. `lib/features/auth/presentation/sign_in_screen.dart` — replace log()
11. `lib/features/auth/presentation/sign_up_screen.dart` — replace log()
12. `lib/features/auth/presentation/forgot_password_email_screen.dart` — replace log()
13. `lib/features/home/presentation/profile_screen.dart` — replace log()
14. `lib/core/widgets/dev_menu_screen.dart` — add "View Logs" button
15. `specs/plan.md` — document the change

## Log level mapping
| Current `log()` usage | Talker equivalent |
|---|---|
| `log('starting...', name: 'X')` | `talker.info('starting...')` |
| `log('success, uid=...', name: 'X')` | `talker.info('success, uid=...')` |
| `log('failed: ...', name: 'X')` | `talker.warning('failed: ...')` |
| `log('error: ...', error: e, stackTrace: st)` | `talker.handle(e, st, 'context message')` |

## Verification
- `flutter pub get` succeeds
- `flutter analyze` — no issues
- Run app → perform sign-in → check terminal for colored structured logs
- Navigate to dev menu → "View Logs" → see all log history in TalkerScreen
- Route changes appear automatically in logs
