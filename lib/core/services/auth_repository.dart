import '../models/user_model.dart';

abstract class AuthRepository {
  static const vocabularyBonusXp = 5;

  Stream<UserModel?> get authStateChanges;

  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String nickname,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<UserModel?> getCurrentUser();

  void updateLanguage(String lang);

  Future<void> addXp(int xp);

  Future<bool> awardVocabularyBonus({required String chapterId});
}
