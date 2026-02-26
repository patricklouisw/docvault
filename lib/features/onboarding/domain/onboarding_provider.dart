import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docvault/features/onboarding/data/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(),
);

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) {
  return ref.read(onboardingRepositoryProvider).hasSeenOnboarding();
});
