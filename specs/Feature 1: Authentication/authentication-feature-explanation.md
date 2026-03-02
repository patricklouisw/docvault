# DocVault Authentication — Architecture & Flow Explanation

This document explains the complete authentication system in DocVault: how users sign up, sign in, and how the app manages auth state. It also serves as a guide for understanding **Riverpod** patterns in a real Flutter app.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Riverpod Provider Chain](#2-riverpod-provider-chain)
3. [User Flows](#3-user-flows)
4. [System Flows (What Happens Under the Hood)](#4-system-flows)
5. [Router Architecture](#5-router-architecture)
6. [Error Handling Patterns](#6-error-handling-patterns)
7. [Loading State Patterns](#7-loading-state-patterns)
8. [File Reference](#8-file-reference)

---

## 1. Architecture Overview

The auth system follows a **three-layer architecture**:

```
┌─────────────────────────────────────────────────────┐
│                   PRESENTATION                       │
│  Screens & Widgets (what the user sees and taps)     │
│  sign_in_screen.dart, sign_up_screen.dart, etc.      │
├─────────────────────────────────────────────────────┤
│                     DOMAIN                           │
│  Riverpod Providers (the glue between layers)        │
│  auth_provider.dart                                  │
├─────────────────────────────────────────────────────┤
│                      DATA                            │
│  Repositories (talk to Firebase)                     │
│  auth_repository.dart, user_repository.dart          │
└─────────────────────────────────────────────────────┘
```

**Why this separation matters:**
- **Screens** never call Firebase directly. They ask a **provider** for a **repository**, then call methods on it.
- **Repositories** contain all Firebase logic. If you ever swap Firebase for another backend, only repositories change.
- **Providers** wire everything together and expose reactive state (like "is the user logged in?") that screens and the router can listen to.

---

## 2. Riverpod Provider Chain

### The Provider Dependency Graph

```
┌──────────────────────┐
│  AuthRepository()    │  ← Plain Dart class, wraps FirebaseAuth
└──────────┬───────────┘
           │ created by
           ▼
┌──────────────────────────────┐
│  authRepositoryProvider      │  ← Provider<AuthRepository>
│  (singleton, never rebuilds) │
└──────────┬───────────────────┘
           │ .authStateChanges()
           ▼
┌──────────────────────────────┐
│  authStateProvider           │  ← StreamProvider<User?>
│  (emits every time user      │     Fires when: sign in, sign out,
│   signs in or out)            │     token refresh
└──────────┬───────────────────┘
           │ .valueOrNull
           ▼
┌──────────────────────────────┐
│  currentUserProvider         │  ← Provider<User?>
│  (null = signed out,          │     Convenient synchronous access
│   User = signed in)           │
└──────────┬───────────────────┘
           │ watched by
           ▼
┌──────────────────────────────┐
│  appRouterProvider           │  ← Provider<GoRouter>
│  (rebuilds router redirect   │     Redirects based on auth state
│   logic when auth changes)    │
└──────────────────────────────┘
```

**Separate providers (no chain dependencies):**

```
┌──────────────────────────────┐
│  userRepositoryProvider      │  ← Provider<UserRepository>
│  (Firestore user doc CRUD)    │     Used after successful auth
└──────────────────────────────┘

┌──────────────────────────────┐
│  signUpFormProvider          │  ← StateNotifierProvider
│  (holds form data across      │     Multi-step sign-up form state
│   sign-up steps)              │
└──────────────────────────────┘
```

### Understanding Provider Types

#### `Provider<T>` — Simple singleton

```dart
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
```

**What it does:** Creates one `AuthRepository` instance and reuses it everywhere. Think of it as a global variable, but managed by Riverpod.

**When to use:** For stateless services or repositories that don't change.

#### `StreamProvider<T>` — Reactive stream listener

```dart
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
```

**What it does:** Listens to Firebase's `authStateChanges()` stream. Every time a user signs in or out, this provider emits a new value. Any widget watching it rebuilds automatically.

**When to use:** For data that changes over time (auth state, Firestore snapshots, WebSocket messages).

**Key insight:** `StreamProvider` wraps the value in `AsyncValue`, so you access it with:
- `.valueOrNull` — returns `T?` (null if loading or error)
- `.when(data: ..., error: ..., loading: ...)` — handle all states

#### `StateNotifierProvider<N, T>` — Mutable state with methods

```dart
final signUpFormProvider =
    StateNotifierProvider<SignUpFormNotifier, SignUpFormData>(
  (ref) => SignUpFormNotifier(),
);
```

**What it does:** Holds mutable state (`SignUpFormData`) and exposes methods to update it (`updateStep1()`, `updateStep2()`, `clear()`). Widgets watching it rebuild when state changes.

**When to use:** For complex state with multiple update operations (forms, counters, filters).

### `ref.watch()` vs `ref.read()` — The Most Important Distinction

#### `ref.watch(provider)` — Reactive, rebuilds on change

```dart
// In app.dart (a ConsumerWidget's build method)
final router = ref.watch(appRouterProvider);
```

**Rule:** Use `ref.watch()` inside `build()` methods. When the provider's value changes, the widget rebuilds with the new value.

**Mental model:** "Keep watching this value. If it changes, rebuild me."

#### `ref.read(provider)` — One-time read, no rebuilds

```dart
// In a button tap handler
Future<void> _onSignIn() async {
  final authRepo = ref.read(authRepositoryProvider);
  await authRepo.signInWithEmail(email: ..., password: ...);
}
```

**Rule:** Use `ref.read()` inside event handlers (onTap, onPressed) and `initState()`. You want the current value but don't need to rebuild when it changes.

**Mental model:** "Give me the value right now. I'll handle the rest."

**Common mistake:** Using `ref.watch()` in an event handler causes unnecessary rebuilds and potential infinite loops.

---

## 3. User Flows

### Flow 1: Email Sign-Up (4 Steps)

```
User opens app
    │
    ▼
[Splash Screen] ──2s delay──▶ [Onboarding] ──"Get Started"──▶ [Login or Sign Up]
                                                                      │
                                                          "Don't have an account?"
                                                                      │
                                                                      ▼
                                                            [Sign Up Method]
                                                                      │
                                                          "Sign up with email"
                                                                      │
                                                                      ▼
                                                    ┌─────────────────────────────┐
                                                    │     Sign Up Screen          │
                                                    │                             │
                                                    │  Step 1: Profile            │
                                                    │  (name, phone, gender, DOB) │
                                                    │         │ "Continue"        │
                                                    │         ▼                   │
                                                    │  Step 2: Account            │
                                                    │  (email, password, confirm) │
                                                    │  → Firebase creates user    │
                                                    │         │ "Continue"        │
                                                    │         ▼                   │
                                                    │  Step 3: Vault Setup        │
                                                    │  (passphrase, confirm)      │
                                                    │         │ "Continue"        │
                                                    │         ▼                   │
                                                    │  Step 4: Recovery Phrase     │
                                                    │  (display, copy, checkbox)  │
                                                    │  → Firestore creates user   │
                                                    │    doc                      │
                                                    │         │ "Continue"        │
                                                    └─────────┼───────────────────┘
                                                              │
                                                              ▼
                                                        [Home Screen]
```

### Flow 2: Social Sign-Up (Google/Apple → 2 Steps)

```
[Sign Up Method]
      │
  Tap "Continue with Google" or "Continue with Apple"
      │
      ▼
  Firebase social auth (popup/redirect)
      │
      ▼
  Create Firestore user doc
      │
      ▼
  Navigate to Sign Up Screen at Step 3 (initialStep: 2)
      │
      ▼
┌─────────────────────────────┐
│  Step 3: Vault Setup        │  ← User starts here
│         │                   │
│         ▼                   │
│  Step 4: Recovery Phrase    │
│         │                   │
└─────────┼───────────────────┘
          │
          ▼
    [Home Screen]
```

**Key insight:** Social sign-up skips Steps 1 & 2 because Google/Apple already provide the user's identity. The `extra: 2` parameter passed via `context.push(AppRoutes.signUp, extra: 2)` tells the sign-up screen to start at step index 2.

### Flow 3: Email Sign-In

```
[Login or Sign Up]
      │
  "Sign in with password"
      │
      ▼
[Sign In Screen]
      │
  Enter email + password, tap "Sign In"
      │
      ▼
  Firebase signInWithEmail()
      │
      ▼
  Create user doc if needed
      │
      ▼
[Vault Unlock Screen]
      │
  Enter passphrase, tap "Unlock"
      │
      ▼
[Home Screen]
```

### Flow 4: Social Sign-In (from Login Screen)

```
[Login or Sign Up]
      │
  Tap "Continue with Google" or "Continue with Apple"
      │
      ▼
  Firebase social auth
      │
      ▼
  Create user doc if needed
      │
      ▼
[Vault Unlock Screen]
      │
      ▼
[Home Screen]
```

### Flow 5: Password Reset

```
[Sign In Screen]
      │
  "Forgot Password?"
      │
      ▼
[Forgot Password Email Screen]
      │
  Enter email, tap "Continue"
      │
      ▼
  Firebase sendPasswordResetEmail()
      │
      ▼
  SnackBar: "Password reset email sent. Check your inbox."
      │
      ▼
  Pop back to [Sign In Screen]
```

**Note:** Firebase handles password reset via email link, not OTP. The OTP screen (`forgot_password_otp_screen.dart`) and new password screen exist in the codebase as UI placeholders for a future custom implementation.

### Flow 6: Returning User (Already Logged In)

```
User opens app (was previously signed in)
      │
      ▼
[Splash Screen]
      │
  Check: FirebaseAuth.instance.currentUser != null?
      │
  YES ─▶ [Vault Unlock Screen] ──unlock──▶ [Home Screen]
      │
  NO  ─▶ Check hasSeenOnboarding
          │
      YES ─▶ [Login or Sign Up]
          │
      NO  ─▶ [Onboarding]
```

---

## 4. System Flows

### What Happens When a User Signs Up with Email

```
Step 2: User taps "Continue"
│
├─ 1. Screen calls:
│     ref.read(authRepositoryProvider).signUpWithEmail(email, password)
│
├─ 2. AuthRepository calls:
│     FirebaseAuth.instance.createUserWithEmailAndPassword(email, password)
│
├─ 3. Firebase creates the user account and returns UserCredential
│
├─ 4. FirebaseAuth emits on authStateChanges() stream
│     → authStateProvider picks this up
│     → currentUserProvider updates to non-null
│     → appRouterProvider's redirect logic now sees user as authenticated
│
├─ 5. Screen advances to Step 3 (vault setup) via PageController.nextPage()
│
│  ... user completes Steps 3 & 4 ...
│
Step 4: User taps "Continue"
│
├─ 6. Screen calls:
│     ref.read(authRepositoryProvider).currentUser!.uid → gets UID
│     ref.read(userRepositoryProvider).createUserIfNotExists(uid)
│
├─ 7. UserRepository checks: does users/{uid} exist in Firestore?
│     NO → creates document with { recentDocumentViews: [], createdAt, updatedAt }
│     YES → does nothing (idempotent)
│
└─ 8. Screen navigates: context.go(AppRoutes.home)
       → Router resolves to /home/documents
```

### What Happens When a User Signs In with Google

```
User taps "Continue with Google"
│
├─ 1. Screen calls:
│     ref.read(authRepositoryProvider).signInWithGoogle()
│
├─ 2. AuthRepository calls:
│     GoogleSignIn().signIn()  → Google OAuth popup/sheet
│     googleUser.authentication → get access token + ID token
│     GoogleAuthProvider.credential(accessToken, idToken) → create Firebase credential
│     FirebaseAuth.instance.signInWithCredential(credential) → sign in
│
├─ 3. Firebase creates or retrieves the user, returns UserCredential
│
├─ 4. authStateProvider updates (same as email flow above)
│
├─ 5. Screen calls:
│     ref.read(userRepositoryProvider).createUserIfNotExists(uid)
│
└─ 6. Screen navigates:
       Login screen → context.go(AppRoutes.vaultUnlock)
       Sign-up screen → context.push(AppRoutes.signUp, extra: 2)
```

### What Happens When the Router Redirects

```
Any navigation event (context.go, context.push, etc.)
│
├─ Router's redirect callback fires
│
├─ Reads: authState.valueOrNull
│   │
│   ├─ User is logged in (non-null):
│   │   │
│   │   ├─ Current path is a public route (login, signup, etc.)?
│   │   │   YES → Redirect to /vault/unlock
│   │   │   (except: splash is always allowed, dev menu in debug mode)
│   │   │
│   │   └─ Current path is a protected route?
│   │       → Allow (no redirect)
│   │
│   └─ User is logged out (null):
│       │
│       ├─ Current path is a protected route?
│       │   YES → Redirect to /login-or-signup
│       │
│       └─ Current path is a public route?
│           → Allow (no redirect)
│
└─ Route resolves, screen renders
```

### What Happens When Auth State Changes

```
Firebase Auth state change (sign in, sign out, token refresh)
│
├─ 1. FirebaseAuth.authStateChanges() emits new User? value
│
├─ 2. authStateProvider (StreamProvider) picks up the emission
│     → Updates its AsyncValue<User?> from AsyncData(oldUser) to AsyncData(newUser)
│
├─ 3. currentUserProvider re-evaluates
│     → ref.watch(authStateProvider).valueOrNull returns new User?
│
├─ 4. appRouterProvider re-evaluates (because it watches authStateProvider)
│     → Creates new GoRouter with updated redirect logic
│
├─ 5. DocVaultApp (in app.dart) rebuilds
│     → ref.watch(appRouterProvider) returns new router
│     → MaterialApp.router gets new routerConfig
│
└─ 6. GoRouter runs redirect logic against current route
       → May redirect user if their auth state no longer matches current route
```

---

## 5. Router Architecture

### Route Definitions

| Route Path | Screen | Auth Required? |
|-----------|--------|----------------|
| `/` | SplashScreen | No (exempt from redirects) |
| `/onboarding` | OnboardingScreen | No |
| `/login-or-signup` | LoginOrSignupScreen | No |
| `/sign-up-method` | SignUpMethodScreen | No |
| `/sign-up` | SignUpScreen | No |
| `/sign-in` | SignInScreen | No |
| `/forgot-password/email` | ForgotPasswordEmailScreen | No |
| `/forgot-password/otp` | ForgotPasswordOtpScreen | No |
| `/forgot-password/new-password` | ForgotPasswordNewPasswordScreen | No |
| `/dev` | DevMenuScreen | No (debug only) |
| `/vault/unlock` | VaultUnlockScreen | Yes |
| `/home/documents` | DocumentsPlaceholderScreen | Yes (ShellRoute) |
| `/home/packages` | PackagesPlaceholderScreen | Yes (ShellRoute) |
| `/home/templates` | TemplatesPlaceholderScreen | Yes (ShellRoute) |
| `/home/profile` | ProfileScreen | Yes (ShellRoute) |

### How the Router Becomes Riverpod-Aware

```dart
// In router.dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);  // ← reactive!

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      // ... redirect logic uses isLoggedIn ...
    },
    routes: [ ... ],
  );
});
```

```dart
// In app.dart
class DocVaultApp extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);  // ← rebuilds when auth changes
    return MaterialApp.router(routerConfig: router);
  }
}
```

**How it works:**
1. `appRouterProvider` calls `ref.watch(authStateProvider)` — this creates a dependency
2. When `authStateProvider` emits a new value (user signs in/out), Riverpod invalidates `appRouterProvider`
3. `appRouterProvider` rebuilds with a new `GoRouter` that has updated redirect logic
4. `DocVaultApp` watches `appRouterProvider`, so it also rebuilds with the new router
5. The new router evaluates redirect logic against the current route

### ShellRoute for Bottom Navigation

```dart
ShellRoute(
  builder: (context, state, child) => HomeShellScreen(child: child),
  routes: [
    GoRoute(path: '/home/documents', ...),
    GoRoute(path: '/home/packages', ...),
    GoRoute(path: '/home/templates', ...),
    GoRoute(path: '/home/profile', ...),
  ],
),
```

`ShellRoute` wraps child routes in a shared shell (`HomeShellScreen` with `NavigationBar`). Switching tabs changes the child but keeps the shell. `NoTransitionPage` prevents animation between tabs.

### Profile Tab & Sign-Out Flow

The Profile tab (`/home/profile`) is a `ConsumerWidget` that displays the current user's initials, display name, and email from `currentUserProvider`. It includes a "Log Out" button that calls `ref.read(authRepositoryProvider).signOut()`. Because the router watches `authStateProvider`, signing out automatically triggers a redirect to `/login-or-signup` — no manual navigation needed.

### Navigation Methods

| Method | Effect | When to use |
|--------|--------|-------------|
| `context.go('/path')` | Replaces the entire navigation stack | After sign-in (user shouldn't go "back" to login) |
| `context.push('/path')` | Pushes onto the stack | Opening a sub-screen (sign-in from login, forgot password) |
| `context.pop()` | Pops the top route | Back button behavior |
| `context.push('/path', extra: data)` | Push with extra data | Passing `initialStep` to sign-up screen |

---

## 6. Error Handling Patterns

### Layer 1: Repository (log + rethrow)

```dart
// In auth_repository.dart
Future<UserCredential> signInWithEmail({...}) async {
  try {
    return await _auth.signInWithEmailAndPassword(...);
  } on FirebaseAuthException catch (e) {
    log('signInWithEmail failed: ${e.code}', name: 'AuthRepository');
    rethrow;  // ← let the screen handle user-facing messaging
  }
}
```

**Pattern:** Repositories log the error for debugging but rethrow it. They don't display messages — that's the screen's job.

### Layer 2: Screen (catch + display)

**Pattern A: Inline error text** (for forms where the error relates to specific fields)

```dart
// In sign_in_screen.dart
try {
  await authRepo.signInWithEmail(email: ..., password: ...);
  context.go(AppRoutes.vaultUnlock);
} on FirebaseAuthException catch (e) {
  setState(() => _errorText = _mapAuthError(e.code));
}
```

The error text is displayed below the form fields in red:

```dart
if (_errorText != null) ...[
  Text(_errorText!, style: TextStyle(color: colorScheme.error)),
],
```

**Pattern B: SnackBar** (for global/transient errors)

```dart
// In login_or_signup_screen.dart
try {
  await signInMethod();
  context.go(AppRoutes.vaultUnlock);
} on FirebaseAuthException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(_mapAuthError(e.code))),
  );
}
```

### Error Code Mapping

Each screen maps Firebase error codes to user-friendly messages:

```dart
String _mapAuthError(String code) {
  switch (code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Invalid email or password.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'sign-in-cancelled':
      return 'Sign-in was cancelled.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
```

**Why map errors?** Firebase error codes like `invalid-credential` are technical. Users need human-readable messages. Each screen maps only the codes relevant to its flow.

---

## 7. Loading State Patterns

### The Pattern: Local `bool _isLoading` with `setState()`

Every screen that makes async calls follows this pattern:

```dart
class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isLoading = false;

  Future<void> _onSignIn() async {
    setState(() => _isLoading = true);     // ← show loading
    try {
      await authRepo.signInWithEmail(...);
      context.go(AppRoutes.vaultUnlock);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = ...);
    } finally {
      if (mounted) setState(() => _isLoading = false);  // ← hide loading
    }
  }
}
```

**Key detail:** The `if (mounted)` check in `finally` prevents calling `setState` after the widget has been disposed (e.g., if navigation happened before the finally block).

### How Loading Flows to Child Widgets

The sign-up screen is a `PageView` with 4 step widgets. The parent screen owns the loading state and passes it down:

```
SignUpScreen (parent — owns _isLoading)
    │
    ├─ SignUpAccountStep(isLoading: _isLoading, errorText: _errorText)
    │   └─ PrimaryButton(isLoading: isLoading, onPressed: isLoading ? null : onContinue)
    │
    └─ SignUpRecoveryPhraseStep(isLoading: _isLoading)
        └─ PrimaryButton(isLoading: isLoading, onPressed: ... ? onContinue : null)
```

**Why not use Riverpod for loading state?** Loading state is local to one screen's async operation. It doesn't need to be shared across the app. Using `setState()` keeps it simple and avoids unnecessary complexity.

### PrimaryButton's Built-in Loading Support

```dart
class PrimaryButton extends StatelessWidget {
  final bool isLoading;

  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,  // ← disabled when loading
      child: isLoading
          ? CircularProgressIndicator(...)        // ← spinner when loading
          : Text(label),
    );
  }
}
```

---

## 8. File Reference

### App Foundation

| File | Role |
|------|------|
| `lib/main.dart` | Firebase initialization, ProviderScope, app entry point |
| `lib/app/app.dart` | `ConsumerWidget` that consumes `appRouterProvider` and applies theme |
| `lib/app/router.dart` | All route definitions, `appRouterProvider` with auth-based redirects |
| `lib/app/theme.dart` | Material 3 theme configuration |

### Auth Domain (Providers)

| File | Role |
|------|------|
| `lib/features/auth/domain/auth_provider.dart` | All Riverpod providers: `authRepositoryProvider`, `authStateProvider`, `currentUserProvider`, `userRepositoryProvider`, `signUpFormProvider`, and `SignUpFormData`/`SignUpFormNotifier` classes |

### Auth Data (Repositories)

| File | Role |
|------|------|
| `lib/features/auth/data/auth_repository.dart` | Firebase Auth operations: email sign-in/up, Google/Apple OAuth, password reset, sign out |
| `lib/features/auth/data/user_repository.dart` | Firestore user document: create if not exists, check vault setup, get user data |

### Auth Screens

| File | Role |
|------|------|
| `lib/features/auth/presentation/login_or_signup_screen.dart` | Entry point: social sign-in buttons + links to sign-in and sign-up |
| `lib/features/auth/presentation/sign_up_method_screen.dart` | Choose social vs email sign-up |
| `lib/features/auth/presentation/sign_up_screen.dart` | 4-step PageView: profile → account → vault → recovery |
| `lib/features/auth/presentation/sign_in_screen.dart` | Email/password sign-in + social icon buttons |
| `lib/features/auth/presentation/forgot_password_email_screen.dart` | Enter email → Firebase sends reset link |
| `lib/features/auth/presentation/forgot_password_otp_screen.dart` | OTP input (UI placeholder, not wired) |
| `lib/features/auth/presentation/forgot_password_new_password_screen.dart` | New password entry (UI placeholder, not wired) |
| `lib/features/auth/presentation/vault_unlock_screen.dart` | Passphrase/recovery phrase input to unlock vault |

### Auth Step Widgets

| File | Role |
|------|------|
| `lib/features/auth/presentation/widgets/sign_up_profile_step.dart` | Step 1: name, phone, gender, DOB, avatar picker |
| `lib/features/auth/presentation/widgets/sign_up_account_step.dart` | Step 2: email, password, confirm, remember me. Accepts `isLoading` and `errorText` |
| `lib/features/auth/presentation/widgets/sign_up_vault_setup_step.dart` | Step 3: create passphrase, confirm passphrase |
| `lib/features/auth/presentation/widgets/sign_up_recovery_phrase_step.dart` | Step 4: display phrase, copy button, save checkbox. Accepts `isLoading` |

### Splash & Onboarding

| File | Role |
|------|------|
| `lib/features/splash/presentation/splash_screen.dart` | Initial auth check: already signed in → vault unlock, else → onboarding or login |
| `lib/features/onboarding/presentation/onboarding_screen.dart` | 3-page onboarding, sets `hasSeenOnboarding` flag |
| `lib/features/onboarding/data/onboarding_repository.dart` | SharedPreferences wrapper for onboarding flag |

### Home

| File | Role |
|------|------|
| `lib/features/home/presentation/home_shell_screen.dart` | Bottom navigation shell with 4 tabs: Documents, Packages, Templates, Profile |
| `lib/features/home/presentation/documents_placeholder_screen.dart` | Documents tab placeholder |
| `lib/features/home/presentation/packages_placeholder_screen.dart` | Packages tab placeholder |
| `lib/features/home/presentation/templates_placeholder_screen.dart` | Templates tab placeholder |
| `lib/features/home/presentation/profile_screen.dart` | Profile tab: shows user info, "Log Out" button calls `authRepository.signOut()` |

---

## Summary: How Everything Connects

```
┌─ main.dart ─────────────────────────────────────────────────────┐
│  Firebase.initializeApp()                                        │
│  ProviderScope(child: DocVaultApp())                             │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─ app.dart ──────────────────────────────────────────────────────┐
│  ref.watch(appRouterProvider) → MaterialApp.router              │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─ router.dart ───────────────────────────────────────────────────┐
│  ref.watch(authStateProvider) → redirect logic                   │
│  Logged in + public route → /vault/unlock                        │
│  Logged out + protected route → /login-or-signup                 │
└──────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
          [Auth Screens]         [Protected Screens]
                    │                   │
                    ▼                   ▼
        ref.read(authRepo)      Home, Documents,
        ref.read(userRepo)      Packages, Templates,
                                Profile (sign-out)
                    │
                    ▼
          [Firebase Auth]
          [Cloud Firestore]
```
