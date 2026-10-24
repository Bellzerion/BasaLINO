// lib/core/models/vocab_hint_model.dart
import 'package:equatable/equatable.dart';

class VocabHintModel extends Equatable {
  const VocabHintModel({
    required this.word,
    required this.definition,
    this.partOfSpeech,
  });

  final String word;
  final String definition;
  final String? partOfSpeech;

  factory VocabHintModel.fromMap(Map<String, dynamic> map) {
    return VocabHintModel(
      word: map['word'] as String? ?? '',
      definition: map['definition'] as String? ?? '',
      partOfSpeech: map['partOfSpeech'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'word': word,
        'definition': definition,
        if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
      };

  @override
  List<Object?> get props => [word, definition];
}
