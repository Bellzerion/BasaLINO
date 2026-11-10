// lib/core/services/progress_repository.dart
import '../models/progress_model.dart';
import '../models/chapter_model.dart';

abstract class ProgressRepository {
  Future<int> getTotalXp(String userId);

  Future<void> awardXp({required String userId, required int amount});

  Future<bool> awardVocabularyBonus({
    required String userId,
    required String chapterId,
    required int xpAwarded,
  });

  Future<Set<String>> getAwardedVocabularyBonusChapterIds({
    required String userId,
  });

  Future<StoryProgressModel?> getStoryProgress({
    required String userId,
    required String storyId,
  });

  Future<List<StoryProgressModel>> getAllProgress(String userId);

  Future<List<RecentAttemptModel>> getRecentAttempts(String userId, {int limit = 10});

  Future<List<ChapterModel>> getChaptersWithStatus({
    required String storyId,
    required String userId,
  });

  Future<bool> recordAttempt({
    required String attemptId,
    required String userId,
    required String storyId,
    required String chapterId,
    required String chapterTitle,
    required int score,
    required int xpAwarded,
    required bool passed,
    String? nextChapterId,
  });

  Future<void> recordChapterCompletion({
    required String userId,
    required String storyId,
    required String chapterId,
    String? nextChapterId,
  });

  Future<void> recordStoryCompletion({
    required String userId,
    required String storyId,
  });

  Future<double?> getReadingPosition({
    required String userId,
    required String storyId,
    required String chapterId,
  });

  Future<void> saveReadingPosition({
    required String userId,
    required String storyId,
    required String chapterId,
    required double position,
  });

  Future<List<String>> getRecentQuestionIds({
    required String userId,
    required String chapterId,
    required String languageCode,
    int limit = 5,
  });

  Future<void> startQuizSnapshot({
    required String userId,
    required QuizAttemptSnapshot snapshot,
  });

  Future<void> completeQuizSnapshot({
    required String userId,
    required String snapshotId,
    required Map<String, String> answers,
  });

  Future<void> recordVocabularyActivity({
    required String userId,
    required String chapterId,
    required String languageCode,
    required String vocabularyId,
    required String word,
    required String activityType,
    required bool correct,
  });

  Future<int> getVocabularyWordsPracticedCount({
    required String userId,
    required Set<String> chapterIds,
  });
}
