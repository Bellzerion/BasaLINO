// lib/core/models/progress_model.dart
import 'package:equatable/equatable.dart';

class StoryProgressModel extends Equatable {
  const StoryProgressModel({
    required this.storyId,
    required this.completedChapterIds,
    required this.currentUnlockedChapterId,
  });

  final String storyId;
  final List<String> completedChapterIds;
  final String? currentUnlockedChapterId;

  int get completedCount => completedChapterIds.length;

  factory StoryProgressModel.fromMap(Map<String, dynamic> map) {
    return StoryProgressModel(
      storyId: map['storyId'] as String? ?? '',
      completedChapterIds:
          List<String>.from(map['completedChapterIds'] as List? ?? []),
      currentUnlockedChapterId: map['currentUnlockedChapterId'] as String?,
    );
  }

  @override
  List<Object?> get props => [storyId, completedChapterIds, currentUnlockedChapterId];
}

class RecentAttemptModel extends Equatable {
  const RecentAttemptModel({
    required this.attemptId,
    required this.chapterId,
    required this.chapterTitle,
    required this.score,
    required this.xpAwarded,
    required this.passed,
    required this.attemptedAt,
  });

  final String attemptId;
  final String chapterId;
  final String chapterTitle;
  final int score;
  final int xpAwarded;
  final bool passed;
  final DateTime attemptedAt;

  factory RecentAttemptModel.fromMap(Map<String, dynamic> map) {
    return RecentAttemptModel(
      attemptId: map['attemptId'] as String? ?? '',
      chapterId: map['chapterId'] as String? ?? '',
      chapterTitle: map['chapterTitle'] as String? ?? '',
      score: map['score'] as int? ?? 0,
      xpAwarded: map['xpAwarded'] as int? ?? 0,
      passed: map['passed'] as bool? ?? false,
      attemptedAt: map['attemptedAt'] != null
          ? (map['attemptedAt'] as dynamic).toDate() as DateTime
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [attemptId, score, passed];
}

class QuizAttemptSnapshot extends Equatable {
  const QuizAttemptSnapshot({
    required this.id,
    required this.bankId,
    required this.bankVersion,
    required this.chapterId,
    required this.languageCode,
    required this.questionIds,
    required this.startedAt,
    this.completedAt,
    this.answers = const {},
  });

  final String id;
  final String bankId;
  final int bankVersion;
  final String chapterId;
  final String languageCode;
  final List<String> questionIds;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, String> answers;

  bool get isComplete => completedAt != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'bankId': bankId,
        'bankVersion': bankVersion,
        'chapterId': chapterId,
        'languageCode': languageCode,
        'questionIds': questionIds,
        'startedAt': startedAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'answers': answers,
      };

  factory QuizAttemptSnapshot.fromMap(Map<String, dynamic> map) =>
      QuizAttemptSnapshot(
        id: map['id'] as String? ?? '',
        bankId: map['bankId'] as String? ?? '',
        bankVersion: map['bankVersion'] as int? ?? 1,
        chapterId: map['chapterId'] as String? ?? '',
        languageCode: map['languageCode'] as String? ?? 'en',
        questionIds: List<String>.from(map['questionIds'] as List? ?? []),
        startedAt: DateTime.parse(map['startedAt'] as String),
        completedAt: map['completedAt'] == null
            ? null
            : DateTime.parse(map['completedAt'] as String),
        answers: Map<String, String>.from(map['answers'] as Map? ?? {}),
      );

  @override
  List<Object?> get props => [id, questionIds, completedAt, answers];
}

class VocabularyActivityRecord extends Equatable {
  const VocabularyActivityRecord({
    required this.id,
    required this.chapterId,
    required this.languageCode,
    required this.word,
    required this.activityType,
    required this.correct,
    required this.completedAt,
  });

  final String id;
  final String chapterId;
  final String languageCode;
  final String word;
  final String activityType;
  final bool correct;
  final DateTime completedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'chapterId': chapterId,
        'languageCode': languageCode,
        'word': word,
        'activityType': activityType,
        'correct': correct,
        'completedAt': completedAt.toIso8601String(),
      };

  factory VocabularyActivityRecord.fromMap(Map<String, dynamic> map) =>
      VocabularyActivityRecord(
        id: map['id'] as String? ?? '',
        chapterId: map['chapterId'] as String? ?? '',
        languageCode: map['languageCode'] as String? ?? 'en',
        word: map['word'] as String? ?? '',
        activityType: map['activityType'] as String? ?? '',
        correct: map['correct'] as bool? ?? false,
        completedAt: DateTime.parse(map['completedAt'] as String),
      );

  @override
  List<Object?> get props => [id, word, activityType, correct];
}
