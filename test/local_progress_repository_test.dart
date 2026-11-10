import 'package:basalino/core/models/chapter_model.dart';
import 'package:basalino/core/models/chapter_translation_model.dart';
import 'package:basalino/core/models/progress_model.dart';
import 'package:basalino/core/models/story_model.dart';
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

  test('chapter progress, attempts, and reading position survive repository restart', () async {
    final repository = LocalProgressRepository(_TestStoryRepository());

    await repository.recordAttempt(
      attemptId: 'attempt-1',
      userId: 'learner-1',
      storyId: 'story-1',
      chapterId: 'chapter-1',
      chapterTitle: 'Chapter 1',
      score: 100,
      xpAwarded: 35,
      passed: true,
      nextChapterId: 'chapter-2',
    );
    await repository.saveReadingPosition(
      userId: 'learner-1',
      storyId: 'story-1',
      chapterId: 'chapter-2',
      position: 412.5,
    );

    final restored = LocalProgressRepository(_TestStoryRepository());
    final progress = await restored.getStoryProgress(
      userId: 'learner-1',
      storyId: 'story-1',
    );
    final attempts = await restored.getRecentAttempts('learner-1');

    expect(progress?.completedChapterIds, ['chapter-1']);
    expect(progress?.currentUnlockedChapterId, 'chapter-2');
    final chapters = await restored.getChaptersWithStatus(
      storyId: 'story-1',
      userId: 'learner-1',
    );
    expect(chapters.map((chapter) => chapter.status), [
      ChapterStatus.completed,
      ChapterStatus.unlocked,
    ]);
    expect(attempts, hasLength(1));
    expect(attempts.single.score, 100);
    expect(attempts.single.xpAwarded, 35);
    expect(attempts.single.passed, isTrue);
    expect(
      await restored.getReadingPosition(
        userId: 'learner-1',
        storyId: 'story-1',
        chapterId: 'chapter-2',
      ),
      412.5,
    );
  });

  test('local XP survives repository restart', () async {
    final repository = LocalProgressRepository(_TestStoryRepository());
    expect(await repository.getTotalXp('demo_learner_1'), 45);
    await repository.awardXp(userId: 'demo_learner_1', amount: 35);

    final restored = LocalProgressRepository(_TestStoryRepository());
    expect(await restored.getTotalXp('demo_learner_1'), 80);
  });

  test('retrying the same attempt does not award XP twice', () async {
    final stories = _TestStoryRepository();
    final repository = LocalProgressRepository(stories);
    final mutations = ProgressMutationService(
      progressRepository: repository,
      storyRepository: stories,
    );

    Future<void> record() => mutations.recordAttempt(
      attemptId: 'stable-attempt-id',
      userId: 'learner-1',
      storyId: 'story-1',
      chapterId: 'chapter-1',
      chapterTitle: 'Chapter 1',
      score: 100,
      xpAwarded: 35,
      passed: true,
      nextChapterId: 'chapter-2',
    );

    await record();
    await record();

    expect(await repository.getTotalXp('learner-1'), 35);
    expect(await repository.getRecentAttempts('learner-1'), hasLength(1));
  });

  test('missing saved progress keeps the initial chapter unlocked', () async {
    final repository = LocalProgressRepository(_TestStoryRepository());

    final chapters = await repository.getChaptersWithStatus(
      storyId: 'story-1',
      userId: 'learner-1',
    );

    expect(chapters.map((chapter) => chapter.status), [
      ChapterStatus.unlocked,
      ChapterStatus.locked,
    ]);
  });

  test('quiz snapshots preserve question IDs for repeat avoidance', () async {
    final repository = LocalProgressRepository(_TestStoryRepository());
    await repository.startQuizSnapshot(
      userId: 'learner-1',
      snapshot: QuizAttemptSnapshot(
        id: 'attempt-1',
        bankId: 'bank-1',
        bankVersion: 1,
        chapterId: 'chapter-1',
        languageCode: 'en',
        questionIds: const ['q1', 'q2', 'q3', 'q4', 'q5'],
        startedAt: DateTime(2026, 1, 1),
      ),
    );
    await repository.completeQuizSnapshot(
      userId: 'learner-1',
      snapshotId: 'attempt-1',
      answers: const {'q1': 'a'},
    );

    final restored = LocalProgressRepository(_TestStoryRepository());
    expect(
      await restored.getRecentQuestionIds(
        userId: 'learner-1',
        chapterId: 'chapter-1',
        languageCode: 'en',
      ),
      const ['q1', 'q2', 'q3', 'q4', 'q5'],
    );
  });
}

class _TestStoryRepository implements StoryRepository {
  @override
  Future<List<StoryModel>> getStories() async => [];

  @override
  Future<List<ChapterModel>> getChapters(String storyId) async => const [
    ChapterModel(
      id: 'chapter-1',
      storyId: 'story-1',
      orderIndex: 0,
      status: ChapterStatus.locked,
    ),
    ChapterModel(
      id: 'chapter-2',
      storyId: 'story-1',
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
