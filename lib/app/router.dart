import 'package:go_router/go_router.dart';

import 'package:docvault/core/widgets/dev_menu_screen.dart';
import 'package:docvault/features/splash/presentation/splash_screen.dart';
import 'package:docvault/features/onboarding/presentation/onboarding_screen.dart';
import 'package:docvault/features/auth/presentation/login_or_signup_screen.dart';
import 'package:docvault/features/auth/presentation/sign_up_step1_screen.dart';
import 'package:docvault/features/auth/presentation/sign_up_step2_screen.dart';
import 'package:docvault/features/auth/presentation/sign_in_screen.dart';
import 'package:docvault/features/auth/presentation/forgot_password_email_screen.dart';
import 'package:docvault/features/auth/presentation/forgot_password_otp_screen.dart';
import 'package:docvault/features/auth/presentation/forgot_password_new_password_screen.dart';
import 'package:docvault/features/vault/presentation/vault_setup_screen.dart';
import 'package:docvault/features/vault/presentation/recovery_phrase_screen.dart';
import 'package:docvault/features/vault/presentation/vault_unlock_screen.dart';
import 'package:docvault/features/home/presentation/home_shell_screen.dart';
import 'package:docvault/features/home/presentation/documents_placeholder_screen.dart';
import 'package:docvault/features/home/presentation/packages_placeholder_screen.dart';
import 'package:docvault/features/home/presentation/templates_placeholder_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const devMenu = '/dev';
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const loginOrSignup = '/login-or-signup';
  static const signUpStep1 = '/sign-up/step1';
  static const signUpStep2 = '/sign-up/step2';
  static const signIn = '/sign-in';
  static const forgotPasswordEmail = '/forgot-password/email';
  static const forgotPasswordOtp = '/forgot-password/otp';
  static const forgotPasswordNewPassword = '/forgot-password/new-password';
  static const vaultSetup = '/vault/setup';
  static const recoveryPhrase = '/vault/recovery-phrase';
  static const vaultUnlock = '/vault/unlock';
  static const home = '/home';
  static const documents = '/home/documents';
  static const packages = '/home/packages';
  static const templates = '/home/templates';
}

final appRouter = GoRouter(
  initialLocation:
      AppRoutes.devMenu, // Change to AppRoutes.splash for production
  routes: [
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
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.loginOrSignup,
      builder: (context, state) => const LoginOrSignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.signUpStep1,
      builder: (context, state) => const SignUpStep1Screen(),
    ),
    GoRoute(
      path: AppRoutes.signUpStep2,
      builder: (context, state) => const SignUpStep2Screen(),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPasswordEmail,
      builder: (context, state) => const ForgotPasswordEmailScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPasswordOtp,
      builder: (context, state) => const ForgotPasswordOtpScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPasswordNewPassword,
      builder: (context, state) => const ForgotPasswordNewPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.vaultSetup,
      builder: (context, state) => const VaultSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.recoveryPhrase,
      builder: (context, state) => const RecoveryPhraseScreen(),
    ),
    GoRoute(
      path: AppRoutes.vaultUnlock,
      builder: (context, state) => const VaultUnlockScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeShellScreen(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.documents,
          builder: (context, state) => const DocumentsPlaceholderScreen(),
        ),
        GoRoute(
          path: AppRoutes.packages,
          builder: (context, state) => const PackagesPlaceholderScreen(),
        ),
        GoRoute(
          path: AppRoutes.templates,
          builder: (context, state) => const TemplatesPlaceholderScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.home,
      redirect: (context, state) => AppRoutes.documents,
    ),
  ],
);
