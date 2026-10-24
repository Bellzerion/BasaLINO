// lib/core/services/progress_repository.dart
import '../models/progress_model.dart';
import '../models/chapter_model.dart';

abstract class ProgressRepository {
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
}
