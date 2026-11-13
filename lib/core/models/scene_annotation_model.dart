// lib/core/models/scene_annotation_model.dart
import 'package:equatable/equatable.dart';

/// Describes an optional illustrated and/or animated moment in a story.
class SceneAnnotationModel extends Equatable {
  const SceneAnnotationModel({
    required this.paragraphIndex,
    this.assetKey = '',
    this.label,
    this.title,
    this.description,
    this.sceneType,
    this.importanceLevel,
    this.imageAssetKey,
    this.educationalNote,
  });

  /// After which paragraph (0-based) this scene should be displayed.
  final int paragraphIndex;

  /// Optional path to a Lottie JSON file, relative to the assets root.
  final String assetKey;

  /// Optional accessibility / caption label shown beneath the animation.
  final String? label;

  final String? title;
  final String? description;
  final String? sceneType;
  final String? importanceLevel;
  final String? imageAssetKey;
  final String? educationalNote;

  factory SceneAnnotationModel.fromMap(Map<String, dynamic> map) {
    return SceneAnnotationModel(
      paragraphIndex: map['paragraphIndex'] as int? ?? 0,
      assetKey: map['assetKey'] as String? ?? '',
      label: map['label'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      sceneType: map['sceneType'] as String?,
      importanceLevel: map['importanceLevel'] as String?,
      imageAssetKey: map['imageAssetKey'] as String?,
      educationalNote: map['educationalNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'paragraphIndex': paragraphIndex,
    if (assetKey.isNotEmpty) 'assetKey': assetKey,
    if (label != null) 'label': label,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (sceneType != null) 'sceneType': sceneType,
    if (importanceLevel != null) 'importanceLevel': importanceLevel,
    if (imageAssetKey != null) 'imageAssetKey': imageAssetKey,
    if (educationalNote != null) 'educationalNote': educationalNote,
  };

  @override
  List<Object?> get props => [
    paragraphIndex,
    assetKey,
    label,
    title,
    description,
    sceneType,
    importanceLevel,
    imageAssetKey,
    educationalNote,
  ];
}
