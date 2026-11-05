import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/user_model.dart';
import '../services/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(user.uid, doc.data()!);
    });
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    return UserModel.fromMap(uid, doc.data()!);
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    final initialUser = UserModel(
      uid: uid,
      email: email,
      nickname: nickname,
      preferredLanguage: 'en',
      approvalStatus:
          ApprovalStatus.pending, // Safeguard defaults to pending for children
      totalXp: 0,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(initialUser.toMap());
    return initialUser;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(user.uid, doc.data()!);
  }

  @override
  void updateLanguage(String lang) {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _firestore.collection('users').doc(uid).update({
        'preferredLanguage': lang,
      });
    }
  }

  @override
  Future<void> addXp(int xp) async {
    // In production, XP is awarded strictly server-side in Cloud Function transactions
  }

  @override
  Future<bool> awardVocabularyBonus({required String chapterId}) async {
    final callable = _functions.httpsCallable('awardVocabularyBonus');
    final response = await callable.call({'chapterId': chapterId});
    final data = Map<String, dynamic>.from(response.data as Map);
    final awarded = data['awarded'];
    if (awarded is! bool) {
      throw const FormatException(
        'Vocabulary bonus response did not include an awarded status.',
      );
    }
    return awarded;
  }
}
