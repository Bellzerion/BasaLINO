// lib/core/models/scene_annotation_model.dart
import 'package:equatable/equatable.dart';

import 'scene_hotspot_model.dart';

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
    this.gifAsset,
    this.educationalNote,
    this.vocabularyContext,
    this.soundEffectAsset,
    this.ambientAudioAsset,
    this.hotspots = const [],
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
  final String? gifAsset;
  final String? educationalNote;
  final String? vocabularyContext;
  final String? soundEffectAsset;
  final String? ambientAudioAsset;
  final List<SceneHotspotModel> hotspots;

  factory SceneAnnotationModel.fromMap(Map<String, dynamic> map) {
    final rawHotspots = map['hotspots'] as List? ?? const [];
    return SceneAnnotationModel(
      paragraphIndex: map['paragraphIndex'] as int? ?? 0,
      assetKey: map['assetKey'] as String? ?? '',
      label: map['label'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      sceneType: map['sceneType'] as String?,
      importanceLevel: map['importanceLevel'] as String?,
      imageAssetKey: map['imageAssetKey'] as String?,
      gifAsset: map['gifAsset'] as String?,
      educationalNote: map['educationalNote'] as String?,
      vocabularyContext: map['vocabularyContext'] as String?,
      soundEffectAsset: map['soundEffectAsset'] as String?,
      ambientAudioAsset: map['ambientAudioAsset'] as String?,
      hotspots: rawHotspots
          .map((item) => SceneHotspotModel.fromMap(item as Map<String, dynamic>))
          .toList(),
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
    if (gifAsset != null) 'gifAsset': gifAsset,
    if (educationalNote != null) 'educationalNote': educationalNote,
    if (vocabularyContext != null) 'vocabularyContext': vocabularyContext,
    if (soundEffectAsset != null) 'soundEffectAsset': soundEffectAsset,
    if (ambientAudioAsset != null) 'ambientAudioAsset': ambientAudioAsset,
    if (hotspots.isNotEmpty)
      'hotspots': hotspots.map((hotspot) => hotspot.toMap()).toList(),
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
    gifAsset,
    educationalNote,
    vocabularyContext,
    soundEffectAsset,
    ambientAudioAsset,
    hotspots,
  ];
}
