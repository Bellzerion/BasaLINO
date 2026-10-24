import 'package:uuid/uuid.dart';
import '../models/progress_model.dart';
import '../models/chapter_model.dart';
import '../services/progress_repository.dart';
import '../services/story_repository.dart';

class LocalProgressRepository implements ProgressRepository {
  final StoryRepository _storyRepo;
  final _uuid = const Uuid();

  // In-memory progress state: userId -> storyId -> StoryProgressModel
  final Map<String, Map<String, StoryProgressModel>> _progressStore = {};
  // In-memory attempts: userId -> List<RecentAttemptModel>
  final Map<String, List<RecentAttemptModel>> _attemptsStore = {};

  LocalProgressRepository(this._storyRepo);

  @override
  Future<StoryProgressModel?> getStoryProgress({
    required String userId,
    required String storyId,
  }) async {
    final userMap = _progressStore[userId];
    if (userMap != null && userMap.containsKey(storyId)) {
      return userMap[storyId];
    }
    // Default initial progress: chapter 1 unlocked, 0 completed
    final initial = StoryProgressModel(
      storyId: storyId,
      completedChapterIds: const [],
      currentUnlockedChapterId: '${storyId}_ch1',
    );
    _progressStore.putIfAbsent(userId, () => {})[storyId] = initial;
    return initial;
  }

  @override
  Future<List<StoryProgressModel>> getAllProgress(String userId) async {
    final userMap = _progressStore[userId] ?? {};
    return userMap.values.toList();
  }

  @override
  Future<List<RecentAttemptModel>> getRecentAttempts(String userId, {int limit = 10}) async {
    final list = _attemptsStore[userId] ?? [];
    return list.take(limit).toList();
  }

  @override
  Future<List<ChapterModel>> getChaptersWithStatus({
    required String storyId,
    required String userId,
  }) async {
    final baseChapters = await _storyRepo.getChapters(storyId);
    final progress = await getStoryProgress(userId: userId, storyId: storyId);

    final completedSet = progress?.completedChapterIds.toSet() ?? {};
    final unlockedCurrent = progress?.currentUnlockedChapterId;

    return baseChapters.map((ch) {
      if (completedSet.contains(ch.id)) {
        return ch.copyWith(status: ChapterStatus.completed);
      } else if (ch.id == unlockedCurrent || ch.orderIndex == 0) {
        return ch.copyWith(status: ChapterStatus.unlocked);
      } else {
        return ch.copyWith(status: ChapterStatus.locked);
      }
    }).toList();
  }

  Future<void> recordAttemptAndUnlock({
    required String userId,
    required String storyId,
    required String chapterId,
    required String chapterTitle,
    required int score,
    required int xpAwarded,
    required bool passed,
    String? nextChapterId,
  }) async {
    final attempt = RecentAttemptModel(
      attemptId: _uuid.v4(),
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      score: score,
      xpAwarded: xpAwarded,
      passed: passed,
      attemptedAt: DateTime.now(),
    );

    _attemptsStore.putIfAbsent(userId, () => []).insert(0, attempt);

    if (passed) {
      final curProgress = await getStoryProgress(userId: userId, storyId: storyId);
      final currentCompleted = List<String>.from(curProgress?.completedChapterIds ?? []);
      if (!currentCompleted.contains(chapterId)) {
        currentCompleted.add(chapterId);
      }

      final updated = StoryProgressModel(
        storyId: storyId,
        completedChapterIds: currentCompleted,
        currentUnlockedChapterId: nextChapterId ?? curProgress?.currentUnlockedChapterId,
      );

      _progressStore.putIfAbsent(userId, () => {})[storyId] = updated;
    }
  }
}
