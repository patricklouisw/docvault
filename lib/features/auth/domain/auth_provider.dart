import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docvault/features/auth/data/auth_repository.dart';
import 'package:docvault/features/auth/data/user_repository.dart';

class SignUpFormData {
  SignUpFormData({
    this.fullName = '',
    this.phoneNumber = '',
    this.gender,
    this.dateOfBirth,
    this.email = '',
    this.password = '',
    this.rememberMe = true,
  });

  final String fullName;
  final String phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final String email;
  final String password;
  final bool rememberMe;

  SignUpFormData copyWith({
    String? fullName,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? email,
    String? password,
    bool? rememberMe,
  }) {
    return SignUpFormData(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

class SignUpFormNotifier extends StateNotifier<SignUpFormData> {
  SignUpFormNotifier() : super(SignUpFormData());

  void updateStep1({
    required String fullName,
    required String phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
  }) {
    state = state.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );
  }

  void updateStep2({
    required String email,
    required String password,
    required bool rememberMe,
  }) {
    state = state.copyWith(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
  }

  void clear() {
    state = SignUpFormData();
  }
}

final signUpFormProvider =
    StateNotifierProvider<SignUpFormNotifier, SignUpFormData>(
  (ref) => SignUpFormNotifier(),
);

// --- Auth Repository & State Providers ---

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authStateProvider).valueOrNull,
);

// --- User Repository Provider ---

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);
