// lib/core/models/challenge_model.dart
import 'package:equatable/equatable.dart';

class ChallengeQuestionModel extends Equatable {
  const ChallengeQuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    this.skill = 'literal_recall',
    this.difficulty = 1,
  });

  final String id;
  final String questionText;
  final List<QuestionOptionModel> options;
  final String skill;
  final int difficulty;

  factory ChallengeQuestionModel.fromMap(Map<String, dynamic> map) {
    return ChallengeQuestionModel(
      id: map['id'] as String? ?? '',
      questionText: map['questionText'] as String? ?? '',
      options: (map['options'] as List? ?? map['choices'] as List? ?? [])
          .asMap()
          .entries
          .map((entry) => QuestionOptionModel.fromMap(
                entry.value is Map
                    ? Map<String, dynamic>.from(entry.value as Map)
                    : {'id': String.fromCharCode(97 + entry.key), 'text': entry.value},
              ))
          .toList(),
      skill: map['skill'] as String? ?? 'literal_recall',
      difficulty: map['difficulty'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [id, questionText, options];
}

class QuestionOptionModel extends Equatable {
  const QuestionOptionModel({required this.id, required this.text});

  final String id;
  final String text;

  factory QuestionOptionModel.fromMap(Map<String, dynamic> map) =>
      QuestionOptionModel(
        id: map['id'] as String? ?? '',
        text: map['text'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, text];
}

class ChallengeModel extends Equatable {
  const ChallengeModel({
    required this.id,
    required this.chapterId,
    required this.languageCode,
    required this.questions,
    this.version = 1,
  });

  final String id;
  final String chapterId;
  final String languageCode;
  final List<ChallengeQuestionModel> questions;
  final int version;

  factory ChallengeModel.fromMap(String id, Map<String, dynamic> map) {
    final rawQuestions = map['questions'] as List? ?? [];
    return ChallengeModel(
      id: id,
      chapterId: map['chapterId'] as String? ?? '',
      languageCode: map['languageCode'] as String? ?? 'en',
      questions: rawQuestions
          .map((e) => ChallengeQuestionModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      version: map['version'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [id, chapterId, languageCode, version, questions];
}
