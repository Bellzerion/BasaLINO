// lib/core/models/chapter_translation_model.dart
import 'package:equatable/equatable.dart';
import 'vocab_hint_model.dart';

class ChapterTranslationModel extends Equatable {
  const ChapterTranslationModel({
    required this.chapterId,
    required this.languageCode,
    required this.title,
    required this.content,
    required this.vocabularyHints,
    this.needsReview = false,
  });

  final String chapterId;
  final String languageCode;
  final String title;
  /// Raw paragraph text — may contain [word] markers for vocabulary hints.
  final String content;
  final List<VocabHintModel> vocabularyHints;
  final bool needsReview;

  factory ChapterTranslationModel.fromMap(Map<String, dynamic> map) {
    final rawHints = map['vocabularyHints'] as List? ?? [];
    return ChapterTranslationModel(
      chapterId: map['chapterId'] as String? ?? '',
      languageCode: map['languageCode'] as String? ?? 'en',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      vocabularyHints: rawHints
          .map((e) => VocabHintModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      needsReview: map['needsReview'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [chapterId, languageCode, title];
}
