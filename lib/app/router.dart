import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docvault/core/widgets/dev_menu_screen.dart';
import 'package:docvault/features/auth/domain/auth_provider.dart';
import 'package:docvault/features/splash/presentation/splash_screen.dart';
import 'package:docvault/features/onboarding/presentation/onboarding_screen.dart';
import 'package:docvault/features/auth/presentation/login_or_signup_screen.dart';
import 'package:docvault/features/auth/presentation/sign_up_screen.dart';
import 'package:docvault/features/auth/presentation/sign_in_screen.dart';
import 'package:docvault/features/auth/presentation/forgot_password_email_screen.dart';
import 'package:docvault/features/auth/presentation/forgot_password_otp_screen.dart';
import 'package:docvault/features/auth/presentation/forgot_password_new_password_screen.dart';
import 'package:docvault/features/vault/presentation/vault_unlock_screen.dart';
import 'package:docvault/features/vault/presentation/vault_check_screen.dart';
import 'package:docvault/features/home/presentation/home_shell_screen.dart';
import 'package:docvault/features/home/presentation/documents_placeholder_screen.dart';
import 'package:docvault/features/home/presentation/packages_placeholder_screen.dart';
import 'package:docvault/features/home/presentation/templates_placeholder_screen.dart';
import 'package:docvault/features/home/presentation/profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const devMenu = '/dev';
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const loginOrSignup = '/login-or-signup';
  static const signUp = '/sign-up';
  static const signIn = '/sign-in';
  static const forgotPasswordEmail = '/forgot-password/email';
  static const forgotPasswordOtp = '/forgot-password/otp';
  static const forgotPasswordNewPassword =
      '/forgot-password/new-password';
  static const vaultCheck = '/vault/check';
  static const vaultUnlock = '/vault/unlock';
  static const home = '/home';
  static const documents = '/home/documents';
  static const packages = '/home/packages';
  static const templates = '/home/templates';
  static const profile = '/home/profile';
}

/// Routes that don't require authentication.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.loginOrSignup,
  AppRoutes.signUp,
  AppRoutes.signIn,
  AppRoutes.forgotPasswordEmail,
  AppRoutes.forgotPasswordOtp,
  AppRoutes.forgotPasswordNewPassword,
  AppRoutes.devMenu,
};

/// Notifier that triggers GoRouter redirect re-evaluation
/// without recreating the entire router.
class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  // Listen (not watch) so the provider is NOT invalidated —
  // the GoRouter instance stays stable, only redirects re-run.
  ref.listen(authStateProvider, (_, _) => refreshNotifier.notify());

  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final isLoggedIn =
          ref.read(authStateProvider).valueOrNull != null;
      final currentPath = state.matchedLocation;

      // Never redirect away from splash — it handles its own navigation.
      if (currentPath == AppRoutes.splash) return null;

      // Authenticated user trying to visit login/signup screens
      // → send them to vault check (setup or unlock).
      if (isLoggedIn && _publicRoutes.contains(currentPath)) {
        // Allow dev menu even when logged in.
        if (currentPath == AppRoutes.devMenu) return null;
        // LoginOrSignupScreen and SignUpScreen handle their own
        // post-auth navigation. Social sign-in users are authenticated
        // but still need to complete the sign-up flow.
        if (currentPath == AppRoutes.loginOrSignup ||
            currentPath == AppRoutes.signUp) {
          return null;
        }
        return AppRoutes.vaultCheck;
      }

      // Unauthenticated user trying to visit protected routes
      // → send them to login.
      if (!isLoggedIn && !_publicRoutes.contains(currentPath)) {
        return AppRoutes.loginOrSignup;
      }

      return null;
    },
    routes: [
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.devMenu,
          builder: (context, state) => const DevMenuScreen(),
        ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginOrSignup,
        builder: (context, state) =>
            const LoginOrSignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => SignUpScreen(
          initialStep: (state.extra as int?) ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordEmail,
        builder: (context, state) =>
            const ForgotPasswordEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordOtp,
        builder: (context, state) =>
            const ForgotPasswordOtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordNewPassword,
        builder: (context, state) =>
            const ForgotPasswordNewPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.vaultCheck,
        builder: (context, state) =>
            const VaultCheckScreen(),
      ),
      GoRoute(
        path: AppRoutes.vaultUnlock,
        builder: (context, state) =>
            const VaultUnlockScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            HomeShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.documents,
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: DocumentsPlaceholderScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.packages,
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: PackagesPlaceholderScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.templates,
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: TemplatesPlaceholderScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.home,
        redirect: (context, state) => AppRoutes.documents,
      ),
    ],
  );
});
