// lib/core/models/vocab_hint_model.dart
import 'package:equatable/equatable.dart';

class VocabHintModel extends Equatable {
  const VocabHintModel({
    required this.vocabularyId,
    required this.word,
    required this.definition,
    this.partOfSpeech,
  });

  final String vocabularyId;
  final String word;
  final String definition;
  final String? partOfSpeech;

  factory VocabHintModel.fromMap(Map<String, dynamic> map) {
    return VocabHintModel(
      vocabularyId: map['vocabularyId'] as String? ?? 'legacy:${map['word']}',
      word: map['word'] as String? ?? '',
      definition: map['definition'] as String? ?? '',
      partOfSpeech: map['partOfSpeech'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'vocabularyId': vocabularyId,
        'word': word,
        'definition': definition,
        if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
      };

  @override
  List<Object?> get props => [vocabularyId, word, definition];
}
