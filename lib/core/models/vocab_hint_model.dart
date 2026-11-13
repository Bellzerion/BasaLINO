// lib/core/models/vocab_hint_model.dart
import 'package:equatable/equatable.dart';

class VocabHintModel extends Equatable {
  const VocabHintModel({
    required this.vocabularyId,
    required this.word,
    required this.definition,
    this.partOfSpeech,
    this.englishTranslation,
    this.tagalogTranslation,
    this.exampleSentence,
    this.illustrationAsset,
    this.audioAsset,
  });

  final String vocabularyId;
  final String word;
  final String definition;
  final String? partOfSpeech;
  final String? englishTranslation;
  final String? tagalogTranslation;
  final String? exampleSentence;
  final String? illustrationAsset;
  final String? audioAsset;

  factory VocabHintModel.fromMap(Map<String, dynamic> map) {
    return VocabHintModel(
      vocabularyId: map['vocabularyId'] as String? ?? 'legacy:${map['word']}',
      word: map['word'] as String? ?? '',
      definition: map['definition'] as String? ?? '',
      partOfSpeech: map['partOfSpeech'] as String?,
      englishTranslation: map['englishTranslation'] as String?,
      tagalogTranslation: map['tagalogTranslation'] as String?,
      exampleSentence: map['exampleSentence'] as String?,
      illustrationAsset: map['illustrationAsset'] as String?,
      audioAsset: map['audioAsset'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'vocabularyId': vocabularyId,
    'word': word,
    'definition': definition,
    if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
    if (englishTranslation != null) 'englishTranslation': englishTranslation,
    if (tagalogTranslation != null) 'tagalogTranslation': tagalogTranslation,
    if (exampleSentence != null) 'exampleSentence': exampleSentence,
    if (illustrationAsset != null) 'illustrationAsset': illustrationAsset,
    if (audioAsset != null) 'audioAsset': audioAsset,
  };

  @override
  List<Object?> get props => [
    vocabularyId,
    word,
    definition,
    partOfSpeech,
    englishTranslation,
    tagalogTranslation,
    exampleSentence,
    illustrationAsset,
    audioAsset,
  ];
}
