# DocVault Feature 1: Authentication + Vault + App Foundation

## Context

The DocVault app implements Feature 1 (Authentication + Vault Setup + Unlock + Recovery) as described in `specs/initial-requirements.md` and `specs/Feature 1: Authentication/feature-1-requirements.md`. The approach is **UI-first**: build all screens with navigation first, then wire up Firebase and crypto logic.

**Current state (Phases 1–5 complete):** All UI screens are built and navigable — splash, onboarding, full auth flows (sign-up with 4-step PageView, sign-in, forgot password), vault unlock, and home shell with 3 placeholder tabs. Firebase dependencies are in `pubspec.yaml` but not initialized. No crypto logic exists yet. Only 1 basic smoke test.

---

## Phase 1: Project Setup & Foundation

- [x] ### 1.1 Update `pubspec.yaml` with dependencies
Add: `flutter_riverpod`, `go_router`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `google_sign_in`, `sign_in_with_apple`, `shared_preferences`, `smooth_page_indicator`, `pinput`, `image_picker`, `google_fonts`, `cryptography`, `intl`
Dev: `riverpod_generator`, `riverpod_annotation`, `build_runner`, `riverpod_lint`
Run `flutter pub get`.

- [x] ### 1.2 Create folder structure
```
lib/
  app/           (app.dart, router.dart, theme.dart)
  core/
    constants/   (app_spacing.dart, app_strings.dart)
    utils/       (validators.dart)
    widgets/     (primary_button, social_button, underline_text_field, password_field, progress_bar, success_dialog, loading_overlay)
  features/
    splash/presentation/
    onboarding/presentation/, data/, domain/
    auth/presentation/, presentation/widgets/, data/, domain/
    vault/presentation/, data/, domain/
    home/presentation/
```

- [x] ### 1.3 Create asset directories
Create `assets/images/` and `assets/icons/` directories. Register in `pubspec.yaml`. Use placeholder `Icon` widgets until real assets are added.

- [x] ### 1.4 Centralized Material 3 theme — `lib/app/theme.dart`
- Seed color: `Color(0xFF5B5FFF)` (blue-purple from mockups)
- `ColorScheme.fromSeed()`, Google Fonts (Inter or similar)
- Underline input decoration theme with blue focus
- ElevatedButton: full-width, 56h, rounded 28px, primary fill
- OutlinedButton: full-width, 56h, rounded 28px
- Checkbox: primary color when selected

- [x] ### 1.5 Spacing constants — `lib/core/constants/app_spacing.dart`
Values: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48

- [x] ### 1.6 String constants — `lib/core/constants/app_strings.dart`
All user-facing strings for splash, onboarding, auth, vault screens.

- [x] ### 1.7 Validators — `lib/core/utils/validators.dart`
Email, password, phone, passphrase match validators.

- [x] ### 1.8 Router — `lib/app/router.dart`
- Route constants in `AppRoutes` class
- `GoRouter` with all routes defined (splash, onboarding, auth screens, vault screens, home shell with `ShellRoute` for bottom nav tabs)
- Redirect logic stubbed (just navigate linearly for now, real auth guards in Phase 6)

- [x] ### 1.9 App entry point — `lib/main.dart` + `lib/app/app.dart`
- `main.dart`: `WidgetsFlutterBinding.ensureInitialized()`, `ProviderScope`, `DocVaultApp()`
- `app.dart`: `ConsumerWidget` with `MaterialApp.router`, theme, router config

- [x] ### 1.10 Shared reusable widgets — `lib/core/widgets/`
| Widget | Description |
|--------|-------------|
| `primary_button.dart` | Full-width rounded blue ElevatedButton with loading state |
| `social_button.dart` | Full-width outlined button with leading icon + label |
| `underline_text_field.dart` | Underline-bordered input with label |
| `password_field.dart` | Underline input with obscure toggle (eye icon) |
| `progress_bar.dart` | Two-segment step indicator (currentStep/totalSteps) |
| `success_dialog.dart` | Modal card: blue circle icon, title, subtitle, action button |

---

## Phase 2: Splash & Onboarding UI

- [x] ### 2.1 Splash Screen — `lib/features/splash/presentation/splash_screen.dart`
- White bg, centered logo icon (`Icons.auto_awesome` placeholder), "DocuVault" text, `CircularProgressIndicator`
- 2s delay then navigate to onboarding (or login if already seen)

- [x] ### 2.2 Onboarding Screen — `lib/features/onboarding/presentation/onboarding_screen.dart`
- `PageView` with 3 pages, each showing: placeholder image area, title, subtitle
- `SmoothPageIndicator` (active = blue pill, inactive = grey dot)
- Skip button (left) + Next button (right); last page: "Get Started" → login screen
- **Extracted widget**: `onboarding_page.dart` for single page

- [x] ### 2.3 Onboarding persistence — `lib/features/onboarding/data/onboarding_repository.dart`
- `SharedPreferences` wrapper for `hasSeenOnboarding` flag
- Riverpod provider in `lib/features/onboarding/domain/onboarding_provider.dart`

---

## Phase 3: Auth UI Screens

- [x] ### 3.1 Login or Sign Up — `lib/features/auth/presentation/login_or_signup_screen.dart`
- Illustration placeholder at top
- "Let's you in" title
- 2 full-width `SocialButton`s: Google, Apple — smart social sign-in:
  - Authenticate → check if Firestore user doc exists
  - **Returning user** (doc exists) → vault unlock
  - **New user** (doc null) → create user doc → sign-up steps 3 & 4 (vault setup + recovery phrase)
- "or" divider row
- "Sign in with password" `PrimaryButton` → sign-in screen
- "Don't have an account? Sign up" link → sign-up screen (full 4-step flow)

> **Removed:** `sign_up_method_screen.dart` — social sign-up is handled directly on the login screen; email sign-up goes straight to sign-up screen.

- [x] ### 3.2 Sign Up (4-step PageView) — `lib/features/auth/presentation/sign_up_screen.dart`
- Single `PageView` with 4 steps, `ProgressBar(currentStep, 4)`, accepts `initialStep` param (0 for email, 2 for social)
- **Step 1 (Profile):** Back arrow, "Complete your profile" + clipboard emoji, avatar with edit overlay, Full Name, Phone, Gender dropdown, DOB picker, "Continue" → step 2
- **Step 2 (Account):** "Create an account" + lock emoji, Email, Password, Confirm Password, "Remember me" checkbox, "Continue" → step 3
- **Step 3 (Vault Setup):** Shield icon, "Secure Your Vault", warning card, Create passphrase + Confirm passphrase, "Continue" → step 4
- **Step 4 (Recovery Phrase):** Key icon, "Your Recovery Phrase", bordered phrase card, "Copy to Clipboard", warning card, "I have saved my recovery phrase" checkbox, "Continue" (gated by checkbox) → home
- Back button pops route on `initialStep`, otherwise goes to previous page
- No success dialog — seamless flow through all steps

- [x] ### 3.5 Sign In — `lib/features/auth/presentation/sign_in_screen.dart`
- "Hello there" + wave emoji, email + password fields
- "Remember me" checkbox, "Forgot Password" link
- "or continue with" + row of 3 small social icons (`social_login_row.dart`)
- "Sign In" button

- [x] ### 3.6 Forgot Password Email — `lib/features/auth/presentation/forgot_password_email_screen.dart`
- "Forgot password" + key emoji, email field, "Continue"

- [x] ### 3.7 Forgot Password OTP — `lib/features/auth/presentation/forgot_password_otp_screen.dart`
- "You've got mail" + envelope emoji, `Pinput` 4-digit input
- Countdown timer for resend, "Confirm"

- [x] ### 3.8 Forgot Password New Password — `lib/features/auth/presentation/forgot_password_new_password_screen.dart`
- "Create new password" + lock emoji, password + confirm fields, "Remember me", "Continue"

- [x] ### 3.9 Reset Success Dialog — `lib/features/auth/presentation/widgets/reset_password_success_dialog.dart`
- Uses `SuccessDialog`: checkmark icon, "Reset Password Successful!", "Go to Home"

- [x] ### 3.10 Auth form state — `lib/features/auth/domain/auth_provider.dart`
- `SignUpFormData` class to hold fields across steps 1 & 2
- `signUpFormProvider` StateNotifier

---

## Phase 4: Vault UI Screens

- [x] ### 4.1 Vault Setup & Recovery Phrase — merged into `sign_up_screen.dart` steps 3 & 4 (see Phase 3.2)
- Standalone files `vault_setup_screen.dart` and `recovery_phrase_screen.dart` removed (per commit `aefcb6e`), routes removed from router

- [x] ### 4.2 Vault Unlock — `lib/features/vault/presentation/vault_unlock_screen.dart`
- Lock icon, "Unlock Your Vault" title
- Passphrase input, "Unlock" button
- "Use recovery phrase instead" toggle link
- Error text display

---

## Phase 5: Home Shell

- [x] ### 5.1 Home Shell — `lib/features/home/presentation/home_shell_screen.dart`
- `Scaffold` + Material 3 `NavigationBar` with 4 tabs
- Documents (`Icons.folder_outlined`), Packages (`Icons.inventory_2_outlined`), Templates (`Icons.description_outlined`), Profile (`Icons.person_outline`)
- Uses `ShellRoute` in go_router

- [x] ### 5.2 Placeholder tabs
- `documents_placeholder_screen.dart` — "Documents - Coming Soon"
- `packages_placeholder_screen.dart` — "Packages - Coming Soon"
- `templates_placeholder_screen.dart` — "Templates - Coming Soon"

- [x] ### 5.3 Profile tab — `lib/features/home/presentation/profile_screen.dart`
- `ConsumerWidget` showing user avatar (initials), display name, email from `currentUserProvider`
- "Log Out" button calls `authRepository.signOut()` → router redirect sends user to `/login-or-signup`
- Route: `/home/profile` added to `ShellRoute` in `router.dart`

---

## Phase 6: Firebase Integration

> **Note:** Firebase dependencies (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `google_sign_in`, `sign_in_with_apple`) are already in `pubspec.yaml` but have never been initialized or called. All auth flows are currently UI-only with placeholder navigation.

- [x] ### 6.1 Firebase project config
- Created Firebase project, ran `flutterfire configure`
- Generated: `lib/firebase_options.dart`

- [x] ### 6.2 Initialize Firebase in `main.dart`
- `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`

- [x] ### 6.3 Auth Repository — `lib/features/auth/data/auth_repository.dart`
- `signInWithEmail()`, `signUpWithEmail()`, `signInWithGoogle()`, `signInWithApple()`
- `sendPasswordResetEmail()`, `signOut()`, `authStateChanges()`, `currentUser`

- [x] ### 6.4 Auth Providers — `lib/features/auth/domain/auth_provider.dart`
- `authRepositoryProvider`, `authStateProvider` (StreamProvider), `currentUserProvider`, `userRepositoryProvider`
- Extends existing `auth_provider.dart` alongside `SignUpFormData` / `signUpFormProvider`

- [x] ### 6.5 Router redirect logic & cleanup
- Converted `appRouter` to `appRouterProvider` (Riverpod-aware, reacts to `authStateProvider`)
- Initial route switched from `/dev` to `/` (splash)
- DevMenu gated behind `kDebugMode`
- Auth guards: unauthenticated → login; authenticated on public routes → vault unlock
- Splash screen checks `FirebaseAuth.instance.currentUser` and skips to vault unlock if logged in
- **Router stability fix:** Changed from `ref.watch(authStateProvider)` (which recreated GoRouter on every auth change, unmounting all screens and breaking in-progress async flows) to `ref.listen` + `refreshListenable` pattern. GoRouter instance is now a stable singleton; auth changes only trigger redirect re-evaluation. Added `_RouterRefreshNotifier` (ChangeNotifier) to bridge Riverpod listener to GoRouter's `refreshListenable`.
- **Redirect exemptions:** `/login-or-signup` and `/sign-up` are excluded from the "authenticated user on public route → vault unlock" redirect. These screens handle their own post-auth navigation (social sign-in users are authenticated via Firebase but still need to complete the sign-up flow before being redirected).

- [x] ### 6.6 Firestore user doc creation on first login
- `lib/features/auth/data/user_repository.dart`: `createUserIfNotExists()`, `hasVaultSetup()`, `getUserData()`
- Creates `users/{uid}` with `recentDocumentViews`, `createdAt`, `updatedAt`
- `userRepositoryProvider` added to `auth_provider.dart`

- [x] ### 6.7 Wire all screen buttons to real auth calls
- All screens converted from `StatelessWidget`/`StatefulWidget` to `ConsumerStatefulWidget` for Riverpod access
- **sign_in_screen.dart**: Email/password sign-in + Google/Apple social sign-in via `authRepositoryProvider`, error display, loading state
- **login_or_signup_screen.dart**: Google/Apple social sign-in buttons wired, Facebook removed (no Firebase support), snackbar errors. Smart routing: checks Firestore user doc — returning users → vault unlock, new users → create doc → sign-up steps 3 & 4
- **sign_up_method_screen.dart**: Removed — social sign-up handled on login screen, email sign-up goes directly to sign-up screen
- **sign_up_screen.dart**: Step 2 calls `signUpWithEmail()` with loading/error in `SignUpAccountStep`; Step 4 calls `createUserIfNotExists()` with loading in `SignUpRecoveryPhraseStep`
- **sign_up_account_step.dart**: Added `isLoading` and `errorText` params
- **sign_up_recovery_phrase_step.dart**: Added `isLoading` param
- **forgot_password_email_screen.dart**: Calls `sendPasswordResetEmail()`, shows snackbar "Check your inbox", pops back (no OTP navigation)

**Note on Forgot Password**: Firebase uses email links, not OTP. OTP screen UI (`forgot_password_otp_screen.dart`) kept for future custom implementation but is no longer navigated to.

---

## Phase 7: Vault Crypto

- [ ] ### 7.1 Crypto Service — `lib/core/services/crypto_service.dart`
- `generateMasterKey()`, `generateSalt()`, `derivePDK()` (Argon2id), `wrapKey()`/`unwrapKey()` (AES-256-GCM), `generateRecoveryPhrase()`

- [ ] ### 7.2 Vault Repository — `lib/features/vault/data/vault_repository.dart`
- `setupVault()`, `setupRecovery()`, `unlockWithPassphrase()`, `unlockWithRecovery()`, `resetPassphrase()`

- [ ] ### 7.3 Vault Providers — `lib/features/vault/domain/vault_provider.dart`
- `VaultState` sealed class: `locked | unlocked(masterKey) | setupRequired | error`
- `VaultNotifier` with setup/unlock/lock/clear methods

- [ ] ### 7.4 Wire vault screens to crypto providers
- Sign-up steps 3–4: Wire `sign_up_vault_setup_step.dart` and `sign_up_recovery_phrase_step.dart` to real crypto (replace hardcoded placeholder phrase and min-8-char validation)
- Vault unlock: Wire `vault_unlock_screen.dart` (currently has placeholder comment `// Placeholder — will be wired to crypto service`)

- [ ] ### 7.5 Logout flow
- Clear MK from memory → `FirebaseAuth.signOut()` → redirect to login

---

## Phase 8: Testing

- [ ] ### 8.1 Set up test structure: `test/widget/`, `test/unit/`, `test/integration/`
- [ ] ### 8.2 Widget tests for shared widgets (primary_button, password_field, success_dialog)
- [ ] ### 8.3 Widget tests for each screen (renders, expected elements present, navigation)
- [ ] ### 8.4 Unit tests for validators
- [ ] ### 8.5 Unit tests for auth/vault providers with mocked Firebase
- [ ] ### 8.6 Replace default `test/widget_test.dart` with `DocVaultApp` smoke test

---

## Verification

1. `flutter pub get` succeeds
2. `flutter analyze` passes with no errors
3. `flutter test` — all widget and unit tests pass
4. `flutter run -d chrome` / `flutter run -d macos` — app launches, full navigation flow works:
   - Splash → Onboarding (3 pages, skip works) → Login/SignUp → Sign Up flow (email: 4 steps, social: 2 steps) → Home (4 tabs)
   - Sign In → Vault Unlock → Home
   - Forgot Password flow (email → OTP → new password → success)
5. After Phase 6: Firebase auth actually creates accounts and signs in
6. After Phase 7: Vault passphrase encrypts/decrypts master key correctly

---

## Estimated remaining file count (Phases 6–8)
- **~15–20 new Dart files** to create (auth repository, auth providers, crypto service, vault repository, vault providers, firebase_options, test files)
- **~5–8 files modified** (`main.dart`, `router.dart`, `auth_provider.dart`, `sign_up_vault_setup_step.dart`, `sign_up_recovery_phrase_step.dart`, `vault_unlock_screen.dart`, sign-in/sign-up screens for wiring)
- **1 file replaced** (`test/widget_test.dart` → proper smoke test)
