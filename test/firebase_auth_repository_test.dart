import 'package:basalino/core/services/auth_repository_exception.dart';
import 'package:basalino/core/services/firebase_auth_repository.dart';
import 'package:basalino/core/services/local_progress_repository.dart';
import 'package:basalino/core/services/local_story_repository.dart';
import 'package:basalino/core/services/progress_mutation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('registration, current user, and auth state use Firebase UID', () async {
    final firebaseAuth = MockFirebaseAuth();
    final repository = FirebaseAuthRepository(auth: firebaseAuth);
    final changes = repository.authStateChanges;
    final receivedUsers = <String?>[];
    final subscription = changes.listen((user) {
      receivedUsers.add(user?.uid);
    });

    final registered = await repository.signUp(
      email: 'learner@example.com',
      password: 'password123',
      nickname: 'Learner',
    );
    await Future<void>.delayed(Duration.zero);

    expect(registered.uid, isNotEmpty);
    expect(registered.email, 'learner@example.com');
    expect(registered.nickname, 'Learner');
    expect((await repository.getCurrentUser())?.uid, registered.uid);
    expect(receivedUsers, contains(registered.uid));

    await repository.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(receivedUsers.last, isNull);

    final signedIn = await repository.signIn(
      email: 'learner@example.com',
      password: 'password123',
    );
    await Future<void>.delayed(Duration.zero);
    expect(signedIn.uid, registered.uid);
    expect(receivedUsers.last, registered.uid);

    await repository.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(receivedUsers.last, isNull);
    await subscription.cancel();
  });

  test(
    'Firebase Auth session remains available to a new repository instance',
    () async {
      final firebaseAuth = MockFirebaseAuth();
      await firebaseAuth.createUserWithEmailAndPassword(
        email: 'restart@example.com',
        password: 'password123',
      );

      final restartedRepository = FirebaseAuthRepository(auth: firebaseAuth);

      expect(
        (await restartedRepository.getCurrentUser())?.email,
        'restart@example.com',
      );
    },
  );

  test('Firebase auth identity is separate from local XP and rewards', () async {
    final repository = FirebaseAuthRepository(auth: MockFirebaseAuth());
    final user = await repository.signUp(
      email: 'progress@example.com',
      password: 'password123',
      nickname: 'Learner',
    );
    final stories = LocalStoryRepository();
    final progress = LocalProgressRepository(stories);
    final mutations = ProgressMutationService(
      progressRepository: progress,
      storyRepository: stories,
    );

    await mutations.awardXp(userId: user.uid, amount: 25);
    expect(await progress.getTotalXp(user.uid), 25);
    expect(
      await mutations.awardVocabularyBonus(
        userId: user.uid,
        chapterId: 'chapter-1',
      ),
      isTrue,
    );
    expect(
      await mutations.awardVocabularyBonus(
        userId: user.uid,
        chapterId: 'chapter-1',
      ),
      isFalse,
    );
    expect(await progress.getTotalXp(user.uid), 30);
    expect(
      await progress.getAwardedVocabularyBonusChapterIds(userId: user.uid),
      {'chapter-1'},
    );
  });

  test('Firebase errors become safe user-facing messages', () async {
    const expectedMessages = {
      'invalid-email': 'Enter a valid email address.',
      'user-not-found': 'Email or password is incorrect.',
      'wrong-password': 'Email or password is incorrect.',
      'email-already-in-use': 'An account already exists for this email.',
    };

    for (final entry in expectedMessages.entries) {
      final exception = mapFirebaseAuthException(
        FirebaseAuthException(
          code: entry.key,
          message: 'Sensitive Firebase backend details',
        ),
      );

      expect(exception, isA<AuthRepositoryException>());
      expect(exception.code, entry.key);
      expect(exception.message, entry.value);
      expect(exception.toString(), entry.value);
    }
  });
}
