import '../models/progress_model.dart';
import 'progress_repository.dart';
import 'story_repository.dart';

class ProgressMutationService {
  const ProgressMutationService({
    required ProgressRepository progressRepository,
    required StoryRepository storyRepository,
  }) : _progressRepository = progressRepository,
       _storyRepository = storyRepository;

  static const vocabularyBonusXp = 5;

  final ProgressRepository _progressRepository;
  final StoryRepository _storyRepository;

  Future<void> awardXp({required String userId, required int amount}) =>
      _progressRepository.awardXp(userId: userId, amount: amount);

  Future<bool> awardVocabularyBonus({
    required String userId,
    required String chapterId,
  }) => _progressRepository.awardVocabularyBonus(
    userId: userId,
    chapterId: chapterId,
    xpAwarded: vocabularyBonusXp,
  );

  Future<void> recordAttempt({
    required String attemptId,
    required String userId,
    required String storyId,
    required String chapterId,
    required String chapterTitle,
    required int score,
    required int xpAwarded,
    required bool passed,
    String? nextChapterId,
  }) async {
    final recorded = await _progressRepository.recordAttempt(
      attemptId: attemptId,
      userId: userId,
      storyId: storyId,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      score: score,
      xpAwarded: xpAwarded,
      passed: passed,
      nextChapterId: nextChapterId,
    );
    if (!recorded) return;
    if (xpAwarded > 0) {
      await awardXp(userId: userId, amount: xpAwarded);
    }
    if (!passed) return;

    final chapters = await _storyRepository.getChapters(storyId);
    if (chapters.isEmpty) return;
    final progress = await _progressRepository.getStoryProgress(
      userId: userId,
      storyId: storyId,
    );
    final completedChapterIds = progress?.completedChapterIds.toSet() ?? {};
    if (chapters.every((chapter) => completedChapterIds.contains(chapter.id))) {
      await recordStoryCompletion(userId: userId, storyId: storyId);
    }
  }

  Future<void> recordChapterCompletion({
    required String userId,
    required String storyId,
    required String chapterId,
    String? nextChapterId,
  }) => _progressRepository.recordChapterCompletion(
    userId: userId,
    storyId: storyId,
    chapterId: chapterId,
    nextChapterId: nextChapterId,
  );

  Future<void> recordStoryCompletion({
    required String userId,
    required String storyId,
  }) => _progressRepository.recordStoryCompletion(
    userId: userId,
    storyId: storyId,
  );

  Future<void> saveReadingPosition({
    required String userId,
    required String storyId,
    required String chapterId,
    required double position,
  }) => _progressRepository.saveReadingPosition(
    userId: userId,
    storyId: storyId,
    chapterId: chapterId,
    position: position,
  );

  Future<void> startQuizSnapshot({
    required String userId,
    required QuizAttemptSnapshot snapshot,
  }) => _progressRepository.startQuizSnapshot(
    userId: userId,
    snapshot: snapshot,
  );

  Future<void> completeQuizSnapshot({
    required String userId,
    required String snapshotId,
    required Map<String, String> answers,
  }) => _progressRepository.completeQuizSnapshot(
    userId: userId,
    snapshotId: snapshotId,
    answers: answers,
  );

  Future<void> recordVocabularyActivity({
    required String userId,
    required String chapterId,
    required String languageCode,
    required String vocabularyId,
    required String word,
    required String activityType,
    required bool correct,
  }) => _progressRepository.recordVocabularyActivity(
    userId: userId,
    chapterId: chapterId,
    languageCode: languageCode,
    vocabularyId: vocabularyId,
    word: word,
    activityType: activityType,
    correct: correct,
  );
}
