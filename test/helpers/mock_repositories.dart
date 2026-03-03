/// Mock implementations of repositories and services for testing.
///
/// Uses [mocktail] to generate mocks without code-gen. These mocks
/// are used throughout unit and screen tests to isolate the code
/// under test from real Firebase / crypto dependencies.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:docvault/core/services/crypto_service.dart';
import 'package:docvault/features/auth/data/auth_repository.dart';
import 'package:docvault/features/auth/data/user_repository.dart';
import 'package:docvault/features/vault/data/vault_repository.dart';

/// Mock for [AuthRepository] — email/password and social auth.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock for [UserRepository] — Firestore user document access.
class MockUserRepository extends Mock implements UserRepository {}

/// Mock for [VaultRepository] — vault setup, unlock, and recovery.
class MockVaultRepository extends Mock implements VaultRepository {}

/// Mock for [CryptoService] — key generation, derivation, wrapping.
class MockCryptoService extends Mock implements CryptoService {}

/// Mock for Firebase [User] — provides uid, displayName, email stubs.
class MockUser extends Mock implements User {}
