import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';
import '../models/chapter_model.dart';
import '../models/chapter_translation_model.dart';
import '../services/story_repository.dart';

class FirebaseStoryRepository implements StoryRepository {
  final FirebaseFirestore _firestore;

  FirebaseStoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<StoryModel>> getStories() async {
    final snap = await _firestore.collection('stories').get();
    return snap.docs.map((doc) => StoryModel.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Future<List<ChapterModel>> getChapters(String storyId) async {
    final snap = await _firestore
        .collection('chapters')
        .where('storyId', isEqualTo: storyId)
        .get();

    final chapters = snap.docs.map((doc) => ChapterModel.fromMap(doc.id, doc.data())).toList();
    chapters.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return chapters;
  }

  @override
  Future<ChapterTranslationModel?> getChapterTranslation({
    required String chapterId,
    required String languageCode,
  }) async {
    // Attempt exact translation
    final transDoc = await _firestore
        .collection('chapterTranslations')
        .doc('${chapterId}_$languageCode')
        .get();

    if (transDoc.exists) {
      return ChapterTranslationModel.fromMap(transDoc.data()!);
    }

    // Fallback to English
    final fallbackDoc = await _firestore
        .collection('chapterTranslations')
        .doc('${chapterId}_en')
        .get();

    if (fallbackDoc.exists) {
      return ChapterTranslationModel.fromMap(fallbackDoc.data()!);
    }

    return null;
  }
}
