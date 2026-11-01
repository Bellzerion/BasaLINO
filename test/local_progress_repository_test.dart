import 'package:basalino/core/models/chapter_model.dart';
import 'package:basalino/core/models/chapter_translation_model.dart';
import 'package:basalino/core/models/story_model.dart';
import 'package:basalino/core/services/local_auth_repository.dart';
import 'package:basalino/core/services/local_progress_repository.dart';
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

    await repository.recordAttemptAndUnlock(
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
    final repository = LocalAuthRepository();
    expect((await repository.getCurrentUser())?.totalXp, 45);

    await repository.addXp(35);

    final restored = LocalAuthRepository();
    expect((await restored.getCurrentUser())?.totalXp, 80);
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
