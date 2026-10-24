// lib/core/models/attempt_result_model.dart
import 'package:equatable/equatable.dart';

class AttemptResultModel extends Equatable {
  const AttemptResultModel({
    required this.attemptId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.xpAwarded,
    required this.passed,
    required this.nextChapterId,
  });

  final String attemptId;
  final int score; // percentage 0–100
  final int totalQuestions;
  final int correctAnswers;
  final int xpAwarded;
  final bool passed;
  final String? nextChapterId;

  factory AttemptResultModel.fromMap(Map<String, dynamic> map) {
    return AttemptResultModel(
      attemptId: map['attemptId'] as String? ?? '',
      score: map['score'] as int? ?? 0,
      totalQuestions: map['totalQuestions'] as int? ?? 0,
      correctAnswers: map['correctAnswers'] as int? ?? 0,
      xpAwarded: map['xpAwarded'] as int? ?? 0,
      passed: map['passed'] as bool? ?? false,
      nextChapterId: map['nextChapterId'] as String?,
    );
  }

  @override
  List<Object?> get props => [attemptId, score, xpAwarded, passed];
}
