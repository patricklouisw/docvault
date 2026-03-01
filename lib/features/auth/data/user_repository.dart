import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Creates the user document if it doesn't already exist.
  /// Called after first sign-up or first social login.
  Future<void> createUserIfNotExists(String uid) async {
    final docRef = _usersRef.doc(uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'recentDocumentViews': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log('Created user doc for $uid', name: 'UserRepository');
    }
  }

  /// Returns true if the user document has crypto metadata set up.
  Future<bool> hasVaultSetup(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    final data = snapshot.data();
    return data != null && data.containsKey('crypto');
  }

  /// Returns the user document data, or null if it doesn't exist.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    return snapshot.data();
  }
}
