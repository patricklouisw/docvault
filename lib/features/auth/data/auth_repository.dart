import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    log('signInWithEmail: starting with email=$email',
        name: 'AuthRepository');
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('signInWithEmail: success, uid=${result.user?.uid}',
          name: 'AuthRepository');
      return result;
    } on FirebaseAuthException catch (e) {
      log('signInWithEmail failed: ${e.code} — ${e.message}',
          name: 'AuthRepository');
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    log('signUpWithEmail: starting with email=$email',
        name: 'AuthRepository');
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('signUpWithEmail: success, uid=${result.user?.uid}',
          name: 'AuthRepository');
      return result;
    } on FirebaseAuthException catch (e) {
      log('signUpWithEmail failed: ${e.code} — ${e.message}',
          name: 'AuthRepository');
      rethrow;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    log('signInWithGoogle: starting Google sign-in flow',
        name: 'AuthRepository');
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        log('signInWithGoogle: user cancelled',
            name: 'AuthRepository');
        throw FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }

      log('signInWithGoogle: got googleUser=${googleUser.email}',
          name: 'AuthRepository');

      final googleAuth = await googleUser.authentication;
      log('signInWithGoogle: got tokens, '
          'accessToken=${googleAuth.accessToken != null}, '
          'idToken=${googleAuth.idToken != null}',
          name: 'AuthRepository');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      log('signInWithGoogle: success, uid=${result.user?.uid}',
          name: 'AuthRepository');
      return result;
    } on FirebaseAuthException {
      rethrow;
    } catch (e, stackTrace) {
      log('signInWithGoogle: unexpected error: $e',
          name: 'AuthRepository',
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<UserCredential> signInWithApple() async {
    log('signInWithApple: starting Apple sign-in flow',
        name: 'AuthRepository');
    try {
      final appleProvider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      final result = await _auth.signInWithProvider(appleProvider);
      log('signInWithApple: success, uid=${result.user?.uid}',
          name: 'AuthRepository');
      return result;
    } on FirebaseAuthException catch (e) {
      log('signInWithApple failed: ${e.code} — ${e.message}',
          name: 'AuthRepository');
      rethrow;
    } catch (e, stackTrace) {
      log('signInWithApple: unexpected error: $e',
          name: 'AuthRepository',
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    log('sendPasswordResetEmail: email=$email',
        name: 'AuthRepository');
    try {
      await _auth.sendPasswordResetEmail(email: email);
      log('sendPasswordResetEmail: success',
          name: 'AuthRepository');
    } on FirebaseAuthException catch (e) {
      log('sendPasswordResetEmail failed: ${e.code} — ${e.message}',
          name: 'AuthRepository');
      rethrow;
    }
  }

  Future<void> signOut() async {
    log('signOut: starting', name: 'AuthRepository');
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
    log('signOut: complete', name: 'AuthRepository');
  }
}
