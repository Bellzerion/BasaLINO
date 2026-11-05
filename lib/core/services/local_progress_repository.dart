import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/progress_model.dart';
import '../models/chapter_model.dart';
import '../services/progress_repository.dart';
import '../services/story_repository.dart';

class LocalProgressRepository implements ProgressRepository {
  static const _storageKey = 'basalino.progress.v1';

  final StoryRepository _storyRepo;
  final _uuid = const Uuid();
  final Map<String, Map<String, StoryProgressModel>> _progressStore = {};
  final Map<String, List<RecentAttemptModel>> _attemptsStore = {};
  final Map<String, Map<String, Map<String, double>>> _readingPositions = {};
  final Map<String, List<QuizAttemptSnapshot>> _quizSnapshots = {};
  final Map<String, List<VocabularyActivityRecord>> _vocabularyRecords = {};

  SharedPreferences? _preferences;
  Future<void>? _loadFuture;

  LocalProgressRepository(this._storyRepo);

  Future<void> _ensureLoaded() => _loadFuture ??= _load();

  Future<void> _load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final json = _preferences!.getString(_storageKey);
    if (json == null) return;

    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic> ||
        (decoded['version'] != 1 && decoded['version'] != 2)) {
      throw const FormatException('Unsupported saved progress format.');
    }

    final users = decoded['users'];
    if (users is! Map) {
      throw const FormatException('Saved progress has no users map.');
    }

    for (final entry in users.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Saved progress contains an invalid user entry.');
      }

      final userId = entry.key as String;
      final userData = Map<String, dynamic>.from(entry.value as Map);
      final progressData = userData['progress'];
      if (progressData is List) {
        _progressStore[userId] = {
          for (final item in progressData)
            if (item is Map)
              (item['storyId'] as String? ?? ''):
                  StoryProgressModel.fromMap(Map<String, dynamic>.from(item)),
        };
      }

      final attemptsData = userData['attempts'];
      if (attemptsData is List) {
        _attemptsStore[userId] = attemptsData
            .whereType<Map>()
            .map((item) => _attemptFromMap(Map<String, dynamic>.from(item)))
            .toList();
      }

      final readingData = userData['readingPositions'];
      if (readingData is Map) {
        _readingPositions[userId] = {
          for (final storyEntry in readingData.entries)
            if (storyEntry.key is String && storyEntry.value is Map)
              storyEntry.key as String: {
                for (final chapterEntry in (storyEntry.value as Map).entries)
                  if (chapterEntry.key is String && chapterEntry.value is num)
                    chapterEntry.key as String:
                        (chapterEntry.value as num).toDouble(),
              },
        };
      }

      final quizData = userData['quizSnapshots'];
      if (quizData is List) {
        _quizSnapshots[userId] = quizData
            .whereType<Map>()
            .map((item) => QuizAttemptSnapshot.fromMap(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
      }
      final vocabularyData = userData['vocabularyRecords'];
      if (vocabularyData is List) {
        _vocabularyRecords[userId] = vocabularyData
            .whereType<Map>()
            .map((item) => VocabularyActivityRecord.fromMap(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
      }
    }
  }

  Map<String, dynamic> _attemptToMap(RecentAttemptModel attempt) => {
        'attemptId': attempt.attemptId,
        'chapterId': attempt.chapterId,
        'chapterTitle': attempt.chapterTitle,
        'score': attempt.score,
        'xpAwarded': attempt.xpAwarded,
        'passed': attempt.passed,
        'attemptedAt': attempt.attemptedAt.toIso8601String(),
      };

  RecentAttemptModel _attemptFromMap(Map<String, dynamic> map) =>
      RecentAttemptModel(
        attemptId: map['attemptId'] as String? ?? '',
        chapterId: map['chapterId'] as String? ?? '',
        chapterTitle: map['chapterTitle'] as String? ?? '',
        score: map['score'] as int? ?? 0,
        xpAwarded: map['xpAwarded'] as int? ?? 0,
        passed: map['passed'] as bool? ?? false,
        attemptedAt: DateTime.parse(map['attemptedAt'] as String),
      );

  Future<void> _save() async {
    final users = <String, dynamic>{};
    for (final userId in {
      ..._progressStore.keys,
      ..._attemptsStore.keys,
      ..._readingPositions.keys,
    }) {
      users[userId] = {
        'progress': (_progressStore[userId]?.values ?? const <StoryProgressModel>[])
            .map((progress) => {
                  'storyId': progress.storyId,
                  'completedChapterIds': progress.completedChapterIds,
                  'currentUnlockedChapterId': progress.currentUnlockedChapterId,
                })
            .toList(),
        'attempts': (_attemptsStore[userId] ?? const <RecentAttemptModel>[])
            .map(_attemptToMap)
            .toList(),
        'readingPositions': _readingPositions[userId] ?? const {},
        'quizSnapshots': (_quizSnapshots[userId] ?? const <QuizAttemptSnapshot>[])
            .take(20)
            .map((snapshot) => snapshot.toMap())
            .toList(),
        'vocabularyRecords':
            (_vocabularyRecords[userId] ?? const <VocabularyActivityRecord>[])
                .take(100)
                .map((record) => record.toMap())
                .toList(),
      };
    }

    final saved = await _preferences!.setString(
      _storageKey,
      jsonEncode({'version': 2, 'users': users}),
    );
    if (!saved) {
      throw StateError('Could not save learner progress to local storage.');
    }
  }

  @override
  Future<StoryProgressModel?> getStoryProgress({
    required String userId,
    required String storyId,
  }) async {
    await _ensureLoaded();
    final userMap = _progressStore[userId];
    if (userMap != null && userMap.containsKey(storyId)) {
      return userMap[storyId];
    }
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
    await _ensureLoaded();
    return (_progressStore[userId] ?? {}).values.toList();
  }

  @override
  Future<List<RecentAttemptModel>> getRecentAttempts(String userId, {int limit = 10}) async {
    await _ensureLoaded();
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

    return baseChapters.map((chapter) {
      if (completedSet.contains(chapter.id)) {
        return chapter.copyWith(status: ChapterStatus.completed);
      } else if (chapter.id == unlockedCurrent || chapter.orderIndex == 0) {
        return chapter.copyWith(status: ChapterStatus.unlocked);
      } else {
        return chapter.copyWith(status: ChapterStatus.locked);
      }
    }).toList();
  }

  Future<double?> getReadingPosition({
    required String userId,
    required String storyId,
    required String chapterId,
  }) async {
    await _ensureLoaded();
    return _readingPositions[userId]?[storyId]?[chapterId];
  }

  Future<void> saveReadingPosition({
    required String userId,
    required String storyId,
    required String chapterId,
    required double position,
  }) async {
    await _ensureLoaded();
    _readingPositions
        .putIfAbsent(userId, () => {})
        .putIfAbsent(storyId, () => {})[chapterId] = position;
    await _save();
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
    await _ensureLoaded();
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

      _progressStore.putIfAbsent(userId, () => {})[storyId] = StoryProgressModel(
        storyId: storyId,
        completedChapterIds: currentCompleted,
        currentUnlockedChapterId: nextChapterId ?? curProgress?.currentUnlockedChapterId,
      );
    }
    await _save();
  }

  Future<List<String>> getRecentQuestionIds({
    required String userId,
    required String chapterId,
    required String languageCode,
    int limit = 5,
  }) async {
    await _ensureLoaded();
    return (_quizSnapshots[userId] ?? const <QuizAttemptSnapshot>[])
        .where((snapshot) =>
            snapshot.chapterId == chapterId &&
            snapshot.languageCode == languageCode)
        .expand((snapshot) => snapshot.questionIds)
        .take(limit)
        .toList();
  }

  Future<void> startQuizSnapshot({
    required String userId,
    required QuizAttemptSnapshot snapshot,
  }) async {
    await _ensureLoaded();
    final snapshots = _quizSnapshots.putIfAbsent(userId, () => []);
    snapshots.removeWhere((item) => item.id == snapshot.id);
    snapshots.insert(0, snapshot);
    await _save();
  }

  Future<void> completeQuizSnapshot({
    required String userId,
    required String snapshotId,
    required Map<String, String> answers,
  }) async {
    await _ensureLoaded();
    final snapshots = _quizSnapshots[userId];
    if (snapshots == null) return;
    final index = snapshots.indexWhere((item) => item.id == snapshotId);
    if (index < 0) return;
    final current = snapshots[index];
    snapshots[index] = QuizAttemptSnapshot(
      id: current.id,
      bankId: current.bankId,
      bankVersion: current.bankVersion,
      chapterId: current.chapterId,
      languageCode: current.languageCode,
      questionIds: current.questionIds,
      startedAt: current.startedAt,
      completedAt: DateTime.now(),
      answers: answers,
    );
    await _save();
  }

  Future<void> recordVocabularyActivity({
    required String userId,
    required String chapterId,
    required String languageCode,
    required String word,
    required String activityType,
    required bool correct,
  }) async {
    await _ensureLoaded();
    _vocabularyRecords.putIfAbsent(userId, () => []).insert(
          0,
          VocabularyActivityRecord(
            id: _uuid.v4(),
            chapterId: chapterId,
            languageCode: languageCode,
            word: word,
            activityType: activityType,
            correct: correct,
            completedAt: DateTime.now(),
          ),
        );
    await _save();
  }
}
