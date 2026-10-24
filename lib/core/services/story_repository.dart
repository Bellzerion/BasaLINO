// lib/core/services/story_repository.dart
import '../models/story_model.dart';
import '../models/chapter_model.dart';
import '../models/chapter_translation_model.dart';

abstract class StoryRepository {
  Future<List<StoryModel>> getStories();

  Future<List<ChapterModel>> getChapters(String storyId);

  Future<ChapterTranslationModel?> getChapterTranslation({
    required String chapterId,
    required String languageCode,
  });
}
