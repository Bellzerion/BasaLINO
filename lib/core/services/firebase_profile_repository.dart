import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile_model.dart';

class FirebaseProfileRepository {
  FirebaseProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<UserProfile?> getProfile(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();
    final data = document.data();
    if (!document.exists || data == null) return null;
    return UserProfile.fromMap(document.id, data);
  }

  Future<bool> profileExists(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();
    return document.exists;
  }

  Future<void> createProfileIfMissing({
    required String uid,
    required String email,
  }) async {
    if (_auth.currentUser?.uid != uid) {
      throw StateError('Cannot create a profile for a different user.');
    }

    final reference = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) return;
      transaction.set(reference, {
        'uid': uid,
        'email': email,
        if (_auth.currentUser?.displayName case final String displayName
            when displayName.isNotEmpty)
          'displayName': displayName,
        'preferredLanguage': 'en',
        'approvalStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
