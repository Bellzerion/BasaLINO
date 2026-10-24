// lib/core/models/story_model.dart
import 'package:equatable/equatable.dart';

class StoryModel extends Equatable {
  const StoryModel({
    required this.id,
    required this.titleEn,
    required this.descriptionEn,
    required this.availableLanguages,
    required this.chapterCount,
    this.coverImageAsset,
    this.createdAt,
  });

  final String id;
  final String titleEn;
  final String descriptionEn;
  final List<String> availableLanguages;
  final int chapterCount;
  final String? coverImageAsset;
  final DateTime? createdAt;

  factory StoryModel.fromMap(String id, Map<String, dynamic> map) {
    return StoryModel(
      id: id,
      titleEn: map['titleEn'] as String? ?? '',
      descriptionEn: map['descriptionEn'] as String? ?? '',
      availableLanguages: List<String>.from(map['availableLanguages'] as List? ?? []),
      chapterCount: map['chapterCount'] as int? ?? 0,
      coverImageAsset: map['coverImageAsset'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate() as DateTime?
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'titleEn': titleEn,
        'descriptionEn': descriptionEn,
        'availableLanguages': availableLanguages,
        'chapterCount': chapterCount,
        if (coverImageAsset != null) 'coverImageAsset': coverImageAsset,
      };

  @override
  List<Object?> get props => [id, titleEn, availableLanguages, chapterCount];
}
