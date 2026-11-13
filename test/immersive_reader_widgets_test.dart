import 'package:basalino/core/models/scene_annotation_model.dart';
import 'package:basalino/core/models/vocab_hint_model.dart';
import 'package:basalino/features/reader/widgets/chapter_scene_widget.dart';
import 'package:basalino/features/reader/widgets/vocabulary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

void main() {
  group('SceneAnnotationModel', () {
    test('reads existing scene maps without new metadata', () {
      final scene = SceneAnnotationModel.fromMap({
        'paragraphIndex': 2,
        'assetKey': 'assets/scenes/volcano_eruption.json',
        'label': 'Mount Mayon is born',
      });

      expect(scene.paragraphIndex, 2);
      expect(scene.assetKey, 'assets/scenes/volcano_eruption.json');
      expect(scene.title, isNull);
      expect(scene.imageAssetKey, isNull);
    });

    test('supports artwork-only scenes and preserves educational metadata', () {
      final scene = SceneAnnotationModel.fromMap({
        'paragraphIndex': 3,
        'title': 'A Story That Endures',
        'description': 'The legend lives on.',
        'sceneType': 'story_ending',
        'importanceLevel': 'high',
        'imageAssetKey': 'assets/images/mayon/story_ending.svg',
        'educationalNote': 'Mayon is an active volcano.',
      });

      expect(scene.assetKey, isEmpty);
      expect(scene.toMap(), {
        'paragraphIndex': 3,
        'title': 'A Story That Endures',
        'description': 'The legend lives on.',
        'sceneType': 'story_ending',
        'importanceLevel': 'high',
        'imageAssetKey': 'assets/images/mayon/story_ending.svg',
        'educationalNote': 'Mayon is an active volcano.',
      });
    });
  });

  testWidgets('vocabulary card shows bilingual meanings and story example', (
    tester,
  ) async {
    final hint = VocabHintModel(
      vocabularyId: 'mayon-ch1-grace',
      word: 'grace',
      definition: 'Elegant movement or manner.',
      partOfSpeech: 'noun',
      englishTranslation: 'grace',
      tagalogTranslation: 'grasya',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryVocabularyCard(
            hint: hint,
            languageCode: 'en',
            exampleSentence: 'Her grace made the people admire her.',
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('grace'), findsNWidgets(2));
    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('grasya'), findsOneWidget);
    expect(find.text('Her grace made the people admire her.'), findsOneWidget);
  });

  testWidgets('scene card opens and closes the immersive viewer', (
    tester,
  ) async {
    const scene = SceneAnnotationModel(
      paragraphIndex: 0,
      assetKey: 'assets/scenes/forest_monsters.json',
      title: 'Baltog Faces Tandayag',
      description: 'Baltog meets the mighty boar.',
      sceneType: 'monster_encounter',
      importanceLevel: 'high',
      imageAssetKey: 'assets/images/ibalong/baltog.svg',
    );
    final controller = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 550),
                ChapterSceneWidget(
                  scene: scene,
                  storyTitle: 'The Heroes of Ibalong',
                  heroTag: 'scene-ibalong-0',
                ),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(350);
    await tester.pump();

    await tester.tap(find.text('Baltog Faces Tandayag'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(find.text('The Heroes of Ibalong'), findsOneWidget);
    expect(find.text('Baltog meets the mighty boar.'), findsOneWidget);
    expect(find.text('Return to Reading'), findsOneWidget);

    await tester.tap(find.text('Return to Reading'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Baltog Faces Tandayag'), findsOneWidget);
    expect(controller.offset, 350);
    controller.dispose();
  });

  testWidgets('scene viewer uses static art when reduced motion is enabled', (
    tester,
  ) async {
    const scene = SceneAnnotationModel(
      paragraphIndex: 0,
      assetKey: 'assets/scenes/volcano_eruption.json',
      title: 'The Rise of Mount Mayon',
      sceneType: 'volcano',
      imageAssetKey: 'assets/images/mayon/eruption.svg',
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(
          body: ChapterSceneWidget(
            scene: scene,
            storyTitle: 'The Tragedy and the Mountain',
            heroTag: 'scene-mayon-volcano',
          ),
        ),
      ),
    );
    await tester.tap(find.text('The Rise of Mount Mayon'));
    await tester.pumpAndSettle();

    expect(find.text('Return to Reading'), findsOneWidget);
    expect(find.text('The Tragedy and the Mountain'), findsOneWidget);
  });

  testWidgets('story artwork and Lottie assets load', (tester) async {
    const artworkAssets = [
      'assets/images/mayon/magayon_introduction.svg',
      'assets/images/mayon/panganoron_at_spring.svg',
      'assets/images/mayon/parotpot_conflict.svg',
      'assets/images/mayon/panganoron_victory.svg',
      'assets/images/mayon/magayon_tragedy.svg',
      'assets/images/mayon/mountain_formation.svg',
      'assets/images/mayon/eruption.svg',
      'assets/images/mayon/story_ending.svg',
      'assets/images/ibalong/monsters.svg',
      'assets/images/ibalong/baltog.svg',
      'assets/images/ibalong/handiong.svg',
      'assets/images/ibalong/bantong.svg',
      'assets/images/ibalong/rabot_encounter.svg',
      'assets/images/ibalong/victory_celebration.svg',
    ];
    const animationAssets = [
      'assets/scenes/_placeholder.json',
      'assets/scenes/battle_scene.json',
      'assets/scenes/disaster_flood.json',
      'assets/scenes/forest_monsters.json',
      'assets/scenes/hero_triumph.json',
      'assets/scenes/peace_celebration.json',
      'assets/scenes/spring_encounter.json',
      'assets/scenes/tragedy_scene.json',
      'assets/scenes/village_nature.json',
      'assets/scenes/volcano_eruption.json',
      'assets/scenes/mayon_battle.json',
      'assets/scenes/mayon_victory.json',
      'assets/scenes/mayon_ending.json',
      'assets/scenes/mayon_formation.json',
    ];

    for (final asset in artworkAssets) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 640,
            height: 360,
            child: SvgPicture.asset(asset),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: asset);
    }

    for (final asset in animationAssets) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 640,
            height: 360,
            child: Lottie.asset(asset, animate: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: asset);
    }
  });
}
