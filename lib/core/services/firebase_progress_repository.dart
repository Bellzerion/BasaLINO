import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progress_model.dart';
import '../models/chapter_model.dart';
import '../services/progress_repository.dart';
import '../services/story_repository.dart';

class FirebaseProgressRepository implements ProgressRepository {
  final FirebaseFirestore _firestore;
  final StoryRepository _storyRepo;

  FirebaseProgressRepository(this._storyRepo, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<StoryProgressModel?> getStoryProgress({
    required String userId,
    required String storyId,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(storyId)
        .get();

    if (!doc.exists) {
      return StoryProgressModel(
        storyId: storyId,
        completedChapterIds: const [],
        currentUnlockedChapterId: '${storyId}_ch1',
      );
    }

    return StoryProgressModel.fromMap(doc.data()!);
  }

  @override
  Future<List<StoryProgressModel>> getAllProgress(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .get();

    return snap.docs.map((doc) => StoryProgressModel.fromMap(doc.data())).toList();
  }

  @override
  Future<List<RecentAttemptModel>> getRecentAttempts(String userId, {int limit = 10}) async {
    final snap = await _firestore
        .collection('attempts')
        .where('userId', isEqualTo: userId)
        .orderBy('attemptedAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((doc) => RecentAttemptModel.fromMap(doc.data())).toList();
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
}
