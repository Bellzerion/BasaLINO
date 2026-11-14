import 'package:equatable/equatable.dart';

class SceneHotspotModel extends Equatable {
  const SceneHotspotModel({
    required this.id,
    required this.title,
    required this.description,
    required this.positionX,
    required this.positionY,
    this.vocabularyIds = const [],
    this.imageAsset,
    this.category,
    this.role,
    this.educationalNote,
  });

  final String id;
  final String title;
  final String description;
  final double positionX;
  final double positionY;
  final List<String> vocabularyIds;
  final String? imageAsset;
  final String? category;
  final String? role;
  final String? educationalNote;

  factory SceneHotspotModel.fromMap(Map<String, dynamic> map) {
    final rawVocabularyIds = map['vocabularyIds'] as List? ?? const [];
    return SceneHotspotModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      positionX: (map['positionX'] as num?)?.toDouble() ?? 0.5,
      positionY: (map['positionY'] as num?)?.toDouble() ?? 0.5,
      vocabularyIds: rawVocabularyIds.whereType<String>().toList(),
      imageAsset: map['imageAsset'] as String?,
      category: map['category'] as String?,
      role: map['role'] as String?,
      educationalNote: map['educationalNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'positionX': positionX,
    'positionY': positionY,
    if (vocabularyIds.isNotEmpty) 'vocabularyIds': vocabularyIds,
    if (imageAsset != null) 'imageAsset': imageAsset,
    if (category != null) 'category': category,
    if (role != null) 'role': role,
    if (educationalNote != null) 'educationalNote': educationalNote,
  };

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    positionX,
    positionY,
    vocabularyIds,
    imageAsset,
    category,
    role,
    educationalNote,
  ];
}
