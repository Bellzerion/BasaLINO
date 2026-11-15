import '../../../core/models/scene_annotation_model.dart';
import '../../../core/models/scene_hotspot_model.dart';

class ArContentModel {
  const ArContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.storyId,
    this.educationalNote,
  });

  final String id;
  final String title;
  final String description;
  final String imageAsset;
  final String storyId;
  final String? educationalNote;

  factory ArContentModel.fromScene({
    required SceneAnnotationModel scene,
    required String storyId,
    SceneHotspotModel? hotspot,
  }) {
    return ArContentModel(
      id: '$storyId-ar-explorer',
      title: hotspot?.title ?? scene.title ?? scene.label ?? 'Mount Mayon',
      description: hotspot?.description ?? scene.description ?? '',
      imageAsset:
          hotspot?.imageAsset ??
          scene.imageAssetKey ??
          'assets/images/mayon/eruption.svg',
      storyId: storyId,
      educationalNote: hotspot?.educationalNote ?? scene.educationalNote,
    );
  }
}
