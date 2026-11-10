import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cloud_progress_model.dart';
import '../models/progress_model.dart';
import '../models/chapter_model.dart';
import 'local_progress_repository.dart';
import '../services/progress_repository.dart';
import '../services/story_repository.dart';

class FirebaseProgressRepository {
  FirebaseProgressRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<CloudProgress?> getProgress(String uid) async {
    final userReference = _firestore.collection('users').doc(uid);
    final profile = await userReference.get();
    final storyProgress = await userReference.collection('progress').get();
    if (!profile.exists && storyProgress.docs.isEmpty) return null;
    return CloudProgress.fromCanonicalDocuments(
      uid: uid,
      profile: profile.data(),
      storyProgress: storyProgress.docs
          .map((document) => {...document.data(), 'storyId': document.id})
          .toList(),
    );
  }
}

class FirebaseStoryProgressRepository implements ProgressRepository {
  final FirebaseFirestore _firestore;
  final StoryRepository _storyRepo;
  final ProgressRepository _localProgress;

  FirebaseStoryProgressRepository(
    this._storyRepo, {
    FirebaseFirestore? firestore,
    ProgressRepository? localProgress,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _localProgress =
           localProgress ?? LocalProgressRepository(_storyRepo);

  @override
  Future<int> getTotalXp(String userId) => _localProgress.getTotalXp(userId);

  @override
  Future<void> awardXp({required String userId, required int amount}) =>
      _localProgress.awardXp(userId: userId, amount: amount);

  @override
  Future<bool> awardVocabularyBonus({
    required String userId,
    required String chapterId,
    required int xpAwarded,
  }) => _localProgress.awardVocabularyBonus(
    userId: userId,
    chapterId: chapterId,
    xpAwarded: xpAwarded,
  );

  @override
  Future<Set<String>> getAwardedVocabularyBonusChapterIds({
    required String userId,
  }) => _localProgress.getAwardedVocabularyBonusChapterIds(userId: userId);

  @override
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
  }) => _localProgress.recordAttempt(
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

  @override
  Future<void> recordChapterCompletion({
    required String userId,
    required String storyId,
    required String chapterId,
    String? nextChapterId,
  }) => _localProgress.recordChapterCompletion(
    userId: userId,
    storyId: storyId,
    chapterId: chapterId,
    nextChapterId: nextChapterId,
  );

  @override
  Future<void> recordStoryCompletion({
    required String userId,
    required String storyId,
  }) => _localProgress.recordStoryCompletion(
    userId: userId,
    storyId: storyId,
  );

  @override
  Future<double?> getReadingPosition({
    required String userId,
    required String storyId,
    required String chapterId,
  }) => _localProgress.getReadingPosition(
    userId: userId,
    storyId: storyId,
    chapterId: chapterId,
  );

  @override
  Future<void> saveReadingPosition({
    required String userId,
    required String storyId,
    required String chapterId,
    required double position,
  }) => _localProgress.saveReadingPosition(
    userId: userId,
    storyId: storyId,
    chapterId: chapterId,
    position: position,
  );

  @override
  Future<List<String>> getRecentQuestionIds({
    required String userId,
    required String chapterId,
    required String languageCode,
    int limit = 5,
  }) => _localProgress.getRecentQuestionIds(
    userId: userId,
    chapterId: chapterId,
    languageCode: languageCode,
    limit: limit,
  );

  @override
  Future<void> startQuizSnapshot({
    required String userId,
    required QuizAttemptSnapshot snapshot,
  }) => _localProgress.startQuizSnapshot(userId: userId, snapshot: snapshot);

  @override
  Future<void> completeQuizSnapshot({
    required String userId,
    required String snapshotId,
    required Map<String, String> answers,
  }) => _localProgress.completeQuizSnapshot(
    userId: userId,
    snapshotId: snapshotId,
    answers: answers,
  );

  @override
  Future<void> recordVocabularyActivity({
    required String userId,
    required String chapterId,
    required String languageCode,
    required String vocabularyId,
    required String word,
    required String activityType,
    required bool correct,
  }) => _localProgress.recordVocabularyActivity(
    userId: userId,
    chapterId: chapterId,
    languageCode: languageCode,
    vocabularyId: vocabularyId,
    word: word,
    activityType: activityType,
    correct: correct,
  );

  @override
  Future<int> getVocabularyWordsPracticedCount({
    required String userId,
    required Set<String> chapterIds,
  }) => _localProgress.getVocabularyWordsPracticedCount(
    userId: userId,
    chapterIds: chapterIds,
  );

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

    return snap.docs
        .map((doc) => StoryProgressModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<List<RecentAttemptModel>> getRecentAttempts(
    String userId, {
    int limit = 10,
  }) async {
    final snap = await _firestore
        .collection('attempts')
        .where('userId', isEqualTo: userId)
        .orderBy('attemptedAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((doc) => RecentAttemptModel.fromMap(doc.data()))
        .toList();
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
