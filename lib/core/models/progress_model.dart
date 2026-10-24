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
