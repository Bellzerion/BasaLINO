import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/story_model.dart';
import '../models/chapter_model.dart';
import '../models/chapter_translation_model.dart';
import '../services/story_repository.dart';

class LocalStoryRepository implements StoryRepository {
  List<StoryModel>? _cachedStories;
  List<Map<String, dynamic>>? _cachedRawChapters;

  @override
  Future<List<StoryModel>> getStories() async {
    if (_cachedStories != null) return _cachedStories!;
    final jsonStr = await rootBundle.loadString('assets/data/stories.json');
    final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
    _cachedStories = data
        .map((e) => StoryModel.fromMap(e['id'] as String, e as Map<String, dynamic>))
        .toList();
    return _cachedStories!;
  }

  Future<List<Map<String, dynamic>>> _loadRawChapters() async {
    if (_cachedRawChapters != null) return _cachedRawChapters!;
    final jsonStr = await rootBundle.loadString('assets/data/chapters.json');
    final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
    _cachedRawChapters = data.map((e) => e as Map<String, dynamic>).toList();
    return _cachedRawChapters!;
  }

  @override
  Future<List<ChapterModel>> getChapters(String storyId) async {
    final raw = await _loadRawChapters();
    final storyChapters = raw.where((e) => e['storyId'] == storyId).toList();
    storyChapters.sort((a, b) => (a['orderIndex'] as int).compareTo(b['orderIndex'] as int));

    return storyChapters.asMap().entries.map((entry) {
      final index = entry.key;
      final e = entry.value;
      return ChapterModel(
        id: e['id'] as String,
        storyId: storyId,
        orderIndex: e['orderIndex'] as int,
        status: index == 0 ? ChapterStatus.unlocked : ChapterStatus.locked,
      );
    }).toList();
  }

  @override
  Future<ChapterTranslationModel?> getChapterTranslation({
    required String chapterId,
    required String languageCode,
  }) async {
    final raw = await _loadRawChapters();
    final chapter = raw.firstWhere(
      (e) => e['id'] == chapterId,
      orElse: () => {},
    );
    if (chapter.isEmpty) return null;

    final translations = chapter['translations'] as Map<String, dynamic>? ?? {};
    var transData = translations[languageCode] as Map<String, dynamic>?;

    // Fallback to English if target language translation is missing
    transData ??= translations['en'] as Map<String, dynamic>?;
    if (transData == null) return null;

    return ChapterTranslationModel.fromMap({
      'chapterId': chapterId,
      'languageCode': languageCode,
      ...transData,
    });
  }
}
