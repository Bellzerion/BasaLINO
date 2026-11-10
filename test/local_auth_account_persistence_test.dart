import 'dart:convert';

import 'package:basalino/core/models/chapter_model.dart';
import 'package:basalino/core/models/chapter_translation_model.dart';
import 'package:basalino/core/models/story_model.dart';
import 'package:basalino/core/services/local_auth_repository.dart';
import 'package:basalino/core/services/local_progress_repository.dart';
import 'package:basalino/core/services/progress_mutation_service.dart';
import 'package:basalino/core/services/story_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'registration and login reuse UID and restore learner progress',
    () async {
      final auth = LocalAuthRepository();
      final registered = await auth.signUp(
        email: 'bel@test.com',
        password: 'password',
        nickname: 'bel',
      );
      final stories = _TestStoryRepository();
      final progress = LocalProgressRepository(stories);
      final mutations = ProgressMutationService(
        progressRepository: progress,
        storyRepository: stories,
      );

      await progress.awardXp(userId: registered.uid, amount: 75);
      await mutations.recordAttempt(
        attemptId: 'attempt-mayon-1',
        userId: registered.uid,
        storyId: 'mayon',
        chapterId: 'mayon_ch1',
        chapterTitle: 'Chapter 1',
        score: 100,
        xpAwarded: 35,
        passed: true,
        nextChapterId: 'mayon_ch2',
      );
      await mutations.recordAttempt(
        attemptId: 'attempt-mayon-2',
        userId: registered.uid,
        storyId: 'mayon',
        chapterId: 'mayon_ch2',
        chapterTitle: 'Chapter 2',
        score: 100,
        xpAwarded: 35,
        passed: true,
      );
      await progress.recordVocabularyActivity(
        userId: registered.uid,
        chapterId: 'mayon_ch2',
        languageCode: 'en',
        vocabularyId: 'mayon-ch2-magayon',
        word: 'magayon',
        activityType: 'recall_challenge',
        correct: true,
      );
      await progress.saveReadingPosition(
        userId: registered.uid,
        storyId: 'mayon',
        chapterId: 'mayon_ch2',
        position: 240,
      );
      await auth.signOut();

      final restoredAuth = LocalAuthRepository();
      final signedIn = await restoredAuth.signIn(
        email: ' BEL@Test.com ',
        password: 'password',
      );
      final restoredProgress = LocalProgressRepository(_TestStoryRepository());

      expect(signedIn.uid, registered.uid);
      expect(await restoredProgress.getTotalXp(signedIn.uid), 145);
      final chapters = await restoredProgress.getChaptersWithStatus(
        storyId: 'mayon',
        userId: signedIn.uid,
      );
      expect(chapters.map((chapter) => chapter.status), [
        ChapterStatus.completed,
        ChapterStatus.completed,
      ]);
      expect(
        (await restoredProgress.getStoryProgress(
          userId: signedIn.uid,
          storyId: 'mayon',
        ))!.completedChapterIds,
        ['mayon_ch1', 'mayon_ch2'],
      );
      expect(
        await restoredProgress.getVocabularyWordsPracticedCount(
          userId: signedIn.uid,
          chapterIds: {'mayon_ch1', 'mayon_ch2'},
        ),
        1,
      );
      expect(
        await restoredProgress.getReadingPosition(
          userId: signedIn.uid,
          storyId: 'mayon',
          chapterId: 'mayon_ch2',
        ),
        240,
      );
    },
  );

  test('separate local accounts cannot access each other progress', () async {
    final auth = LocalAuthRepository();
    final userA = await auth.signUp(
      email: 'a@test.com',
      password: 'password',
      nickname: 'A',
    );
    final progress = LocalProgressRepository(_TestStoryRepository());
    await progress.recordAttempt(
      attemptId: 'attempt-user-a',
      userId: userA.uid,
      storyId: 'mayon',
      chapterId: 'mayon_ch1',
      chapterTitle: 'Chapter 1',
      score: 100,
      xpAwarded: 35,
      passed: true,
      nextChapterId: 'mayon_ch2',
    );
    await auth.signOut();

    final userB = await LocalAuthRepository().signUp(
      email: 'b@test.com',
      password: 'password',
      nickname: 'B',
    );
    final userBProgress = LocalProgressRepository(_TestStoryRepository());

    expect(userB.uid, isNot(userA.uid));
    expect(await userBProgress.getAllProgress(userB.uid), isEmpty);
    expect(
      (await userBProgress.getChaptersWithStatus(
        storyId: 'mayon',
        userId: userB.uid,
      )).map((chapter) => chapter.status),
      [ChapterStatus.unlocked, ChapterStatus.locked],
    );
    expect(
      (await userBProgress.getStoryProgress(
        userId: userA.uid,
        storyId: 'mayon',
      ))!.completedChapterIds,
      ['mayon_ch1'],
    );
  });

  test(
    'local account records retain a stable UID in SharedPreferences',
    () async {
      final auth = LocalAuthRepository();
      final user = await auth.signUp(
        email: 'xp@test.com',
        password: 'password',
        nickname: 'XP Learner',
      );
      final progress = LocalProgressRepository(_TestStoryRepository());
      await progress.awardXp(userId: user.uid, amount: 40);
      await auth.signOut();

      final restored = await LocalAuthRepository().signIn(
        email: 'xp@test.com',
        password: 'password',
      );
      final restoredProgress = LocalProgressRepository(_TestStoryRepository());
      final preferences = await SharedPreferences.getInstance();
      final accountData = jsonDecode(
        preferences.getString('basalino.localAccounts.v1')!,
      ) as Map<String, dynamic>;

      expect(restored.uid, user.uid);
      expect(await restoredProgress.getTotalXp(user.uid), 40);
      expect(accountData['xp@test.com']['uid'], user.uid);
      expect(preferences.getInt('basalino.user.xp.v1.${user.uid}'), 40);
    },
  );

  test('account changes do not clear unlinked legacy progress data', () async {
    const legacyProgress =
        '{"version":2,"users":{"550e8400-e29b-41d4-a716-446655440000":'
        '{"progress":[{"storyId":"mayon","completedChapterIds":["mayon_ch1"],'
        '"currentUnlockedChapterId":"mayon_ch2"}]}}}';
    SharedPreferences.setMockInitialValues({
      'basalino.progress.v1': legacyProgress,
    });

    final auth = LocalAuthRepository();
    await auth.signUp(
      email: 'legacy@test.com',
      password: 'password',
      nickname: 'Legacy',
    );
    await auth.signOut();
    await LocalAuthRepository().signIn(
      email: 'legacy@test.com',
      password: 'password',
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('basalino.progress.v1'), legacyProgress);
  });

  test('completed story remains complete after sign-out and sign-in', () async {
    final auth = LocalAuthRepository();
    final user = await auth.signUp(
      email: 'story@test.com',
      password: 'password',
      nickname: 'Story Learner',
    );
    final progress = LocalProgressRepository(_TestStoryRepository());
    for (final chapterId in ['mayon_ch1', 'mayon_ch2']) {
      await progress.recordAttempt(
        attemptId: 'attempt-story-$chapterId',
        userId: user.uid,
        storyId: 'mayon',
        chapterId: chapterId,
        chapterTitle: chapterId,
        score: 100,
        xpAwarded: 35,
        passed: true,
        nextChapterId: chapterId == 'mayon_ch1' ? 'mayon_ch2' : null,
      );
    }
    await auth.signOut();

    final signedIn = await LocalAuthRepository().signIn(
      email: 'story@test.com',
      password: 'password',
    );
    final chapters = await LocalProgressRepository(_TestStoryRepository())
        .getChaptersWithStatus(storyId: 'mayon', userId: signedIn.uid);

    expect(signedIn.uid, user.uid);
    expect(chapters.every((chapter) => chapter.isCompleted), isTrue);
  });
}

class _TestStoryRepository implements StoryRepository {
  @override
  Future<List<StoryModel>> getStories() async => const [
    StoryModel(
      id: 'mayon',
      titleEn: 'The Legend of Mount Mayon',
      descriptionEn: 'Test story.',
      availableLanguages: ['en'],
      chapterCount: 2,
    ),
  ];

  @override
  Future<List<ChapterModel>> getChapters(String storyId) async => const [
    ChapterModel(
      id: 'mayon_ch1',
      storyId: 'mayon',
      orderIndex: 0,
      status: ChapterStatus.locked,
    ),
    ChapterModel(
      id: 'mayon_ch2',
      storyId: 'mayon',
      orderIndex: 1,
      status: ChapterStatus.locked,
    ),
  ];

  @override
  Future<ChapterTranslationModel?> getChapterTranslation({
    required String chapterId,
    required String languageCode,
  }) async => null;
}
