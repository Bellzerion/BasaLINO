import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'auth_repository.dart';
import 'auth_repository_exception.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  UserModel? _latestUser;
  final Map<String, String> _languageOverrides = {};
  final StreamController<UserModel?> _localChanges =
      StreamController<UserModel?>.broadcast();

  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<UserModel?> get authStateChanges =>
      Stream<UserModel?>.multi((controller) {
        final authSubscription = _auth.authStateChanges().listen(
          (user) => unawaited(_publishFirebaseUser(user, controller)),
          onError: controller.addError,
        );
        final localSubscription = _localChanges.stream.listen(
          controller.add,
          onError: controller.addError,
        );
        controller.onCancel = () async {
          await authSubscription.cancel();
          await localSubscription.cancel();
        };
      });

  Future<void> _publishFirebaseUser(
    User? user,
    MultiStreamController<UserModel?> controller,
  ) async {
    try {
      final mappedUser = await _mapUser(user);
      _latestUser = mappedUser;
      controller.add(mappedUser);
    } catch (error, stackTrace) {
      controller.addError(error, stackTrace);
    }
  }

  Future<UserModel?> _mapUser(User? user) async {
    if (user == null) return null;
    final preferences = await SharedPreferences.getInstance();
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      nickname: user.displayName ?? user.email?.split('@').first ?? '',
      preferredLanguage: _languageOverrides[user.uid] ?? 'en',
      approvalStatus: ApprovalStatus.approved,
      totalXp: preferences.getInt(_xpKey(user.uid)) ?? 0,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  String _xpKey(String uid) => 'basalino.user.xp.v1.$uid';
  String _vocabularyBonusKey(String uid) => 'basalino.vocabularyBonus.v1.$uid';

  User _requireFirebaseUser(User? user) {
    if (user == null) {
      throw const AuthRepositoryException(
        code: 'missing-user',
        message: 'Authentication failed. Please try again.',
      );
    }
    return user;
  }

  Future<void> _publishLatestUser() async {
    _latestUser = await _mapUser(_auth.currentUser);
    _localChanges.add(_latestUser);
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = (await _mapUser(_requireFirebaseUser(credential.user)))!;
      _latestUser = user;
      _localChanges.add(user);
      return user;
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _requireFirebaseUser(credential.user);
      await user.updateDisplayName(nickname);
      final mappedUser = (await _mapUser(user))!.copyWith(nickname: nickname);
      _latestUser = mappedUser;
      _localChanges.add(mappedUser);
      return mappedUser;
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _latestUser = null;
      _localChanges.add(null);
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    _latestUser = await _mapUser(_auth.currentUser);
    return _latestUser;
  }

  @override
  Future<Set<String>> getAwardedVocabularyBonusChapterIds({
    required String userId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_vocabularyBonusKey(userId)) ?? [])
        .toSet();
  }

  @override
  void updateLanguage(String lang) {
    final user = _latestUser;
    if (user == null) return;
    _languageOverrides[user.uid] = lang;
    _latestUser = user.copyWith(preferredLanguage: lang);
    _localChanges.add(_latestUser);
  }

  @override
  Future<void> addXp(int xp) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final preferences = await SharedPreferences.getInstance();
    final totalXp = (preferences.getInt(_xpKey(user.uid)) ?? 0) + xp;
    final saved = await preferences.setInt(_xpKey(user.uid), totalXp);
    if (!saved) {
      throw StateError('Could not save learner XP to local storage.');
    }
    await _publishLatestUser();
  }

  @override
  Future<bool> awardVocabularyBonus({required String chapterId}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final preferences = await SharedPreferences.getInstance();
    final key = _vocabularyBonusKey(user.uid);
    final awardedChapters = preferences.getStringList(key) ?? [];
    if (awardedChapters.contains(chapterId)) return false;

    final saved = await preferences.setStringList(key, [
      ...awardedChapters,
      chapterId,
    ]);
    if (!saved) {
      throw StateError('Could not save vocabulary bonus progress.');
    }
    await addXp(AuthRepository.vocabularyBonusXp);
    return true;
  }
}
