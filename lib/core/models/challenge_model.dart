// lib/core/models/challenge_model.dart
import 'package:equatable/equatable.dart';

class ChallengeQuestionModel extends Equatable {
  const ChallengeQuestionModel({
    required this.id,
    required this.questionText,
    required this.choices,
  });

  final String id;
  final String questionText;
  final List<String> choices;

  factory ChallengeQuestionModel.fromMap(Map<String, dynamic> map) {
    return ChallengeQuestionModel(
      id: map['id'] as String? ?? '',
      questionText: map['questionText'] as String? ?? '',
      choices: List<String>.from(map['choices'] as List? ?? []),
    );
  }

  @override
  List<Object?> get props => [id, questionText];
}

class ChallengeModel extends Equatable {
  const ChallengeModel({
    required this.id,
    required this.chapterId,
    required this.languageCode,
    required this.questions,
  });

  final String id;
  final String chapterId;
  final String languageCode;
  final List<ChallengeQuestionModel> questions;

  factory ChallengeModel.fromMap(String id, Map<String, dynamic> map) {
    final rawQuestions = map['questions'] as List? ?? [];
    return ChallengeModel(
      id: id,
      chapterId: map['chapterId'] as String? ?? '',
      languageCode: map['languageCode'] as String? ?? 'en',
      questions: rawQuestions
          .map((e) => ChallengeQuestionModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, chapterId, languageCode];
}
