import 'package:basalino/core/services/auth_repository_exception.dart';
import 'package:basalino/core/services/firebase_auth_repository.dart';
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

  test('Firebase-mode XP and vocabulary bonuses remain local', () async {
    final repository = FirebaseAuthRepository(auth: MockFirebaseAuth());
    final user = await repository.signUp(
      email: 'progress@example.com',
      password: 'password123',
      nickname: 'Learner',
    );

    await repository.addXp(25);
    expect((await repository.getCurrentUser())?.totalXp, 25);
    expect(
      await repository.awardVocabularyBonus(chapterId: 'chapter-1'),
      isTrue,
    );
    expect(
      await repository.awardVocabularyBonus(chapterId: 'chapter-1'),
      isFalse,
    );
    expect((await repository.getCurrentUser())?.totalXp, 30);
    expect(
      await repository.getAwardedVocabularyBonusChapterIds(userId: user.uid),
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
