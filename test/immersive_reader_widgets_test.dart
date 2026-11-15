import 'dart:async';
import 'dart:convert';

import 'package:basalino/core/models/scene_annotation_model.dart';
import 'package:basalino/core/models/scene_hotspot_model.dart';
import 'package:basalino/core/models/vocab_hint_model.dart';
import 'package:basalino/core/services/story_discovery_tracker.dart';
import 'package:basalino/features/ar/models/ar_content_model.dart';
import 'package:basalino/features/ar/presentation/ar_explorer_screen.dart';
import 'package:basalino/features/ar/services/ar_service.dart';
import 'package:basalino/features/reader/widgets/chapter_scene_widget.dart';
import 'package:basalino/features/reader/widgets/vocabulary_card.dart';
import 'package:basalino/features/reader/presentation/story_codex_screen.dart';
import 'package:basalino/features/reader/services/vocabulary_pronunciation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('chapter scene and vocabulary media references are bundled', () async {
    final chapterBytes = await rootBundle.load('assets/data/chapters.json');
    final chapters = jsonDecode(
      utf8.decode(chapterBytes.buffer.asUint8List()),
    ) as List<dynamic>;
    final mediaAssets = <String>{};

    void addAsset(Object? path) {
      if (path is String && path.isNotEmpty) mediaAssets.add(path);
    }

    for (final chapter in chapters.cast<Map<String, dynamic>>()) {
      for (final scene in (chapter['scenes'] as List<dynamic>? ?? [])) {
        if (scene is! Map<String, dynamic>) continue;
        addAsset(scene['assetKey']);
        addAsset(scene['gifAsset']);
        addAsset(scene['imageAssetKey']);
        addAsset(scene['soundEffectAsset']);
        addAsset(scene['ambientAudioAsset']);
        for (final rawHotspot in (scene['hotspots'] as List<dynamic>? ?? [])) {
          if (rawHotspot is! Map<String, dynamic>) continue;
          addAsset(rawHotspot['imageAsset']);
          expect(rawHotspot['id'], isNotEmpty);
          expect(rawHotspot['positionX'], inInclusiveRange(0, 1));
          expect(rawHotspot['positionY'], inInclusiveRange(0, 1));
        }
      }

      final translations = chapter['translations'] as Map<String, dynamic>;
      for (final translationEntry in translations.entries) {
        final translation = translationEntry.value;
        if (translation is! Map<String, dynamic>) continue;
        final audioFolder = switch (translationEntry.key) {
          'en' => 'english',
          'tl' => 'tagalog',
          'bik' => 'bikol',
          _ => null,
        };
        for (final hint
            in (translation['vocabularyHints'] as List<dynamic>? ?? [])) {
          if (hint is! Map<String, dynamic>) continue;
          final audioAsset = hint['audioAsset'];
          addAsset(audioAsset);
          if (audioAsset is String && audioFolder != null) {
            expect(
              audioAsset.startsWith('assets/audio/$audioFolder/'),
              isTrue,
              reason: 'Pronunciation audio must match ${translationEntry.key}.',
            );
          }
          addAsset(hint['illustrationAsset']);
        }
      }
    }

    for (final asset in mediaAssets) {
      await rootBundle.load(asset);
    }
    expect(mediaAssets.where((asset) => asset.endsWith('.gif')).length, 6);
    expect(
      mediaAssets,
      containsAll([
        'assets/gifs/mayon/scenes/meet magayon.gif',
        'assets/gifs/mayon/scenes/spring_encounter.gif',
        'assets/gifs/mayon/scenes/parotpot.gif',
        'assets/gifs/mayon/scenes/village_rally.gif',
      ]),
    );
    await rootBundle.load('assets/models/mayon_billboard.gltf');
  });

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

    test('round-trips optional GIF, sound, and vocabulary metadata', () {
      final scene = SceneAnnotationModel.fromMap({
        'paragraphIndex': 4,
        'gifAsset': 'assets/gifs/mayon/eruption.gif',
        'soundEffectAsset': 'assets/audio/sfx/volcano_rumble.mp3',
        'vocabularyContext': 'sumabog means to erupt.',
      });

      expect(scene.gifAsset, 'assets/gifs/mayon/eruption.gif');
      expect(scene.soundEffectAsset, 'assets/audio/sfx/volcano_rumble.mp3');
      expect(scene.toMap(), {
        'paragraphIndex': 4,
        'gifAsset': 'assets/gifs/mayon/eruption.gif',
        'soundEffectAsset': 'assets/audio/sfx/volcano_rumble.mp3',
        'vocabularyContext': 'sumabog means to erupt.',
      });
    });

    test('round-trips optional hotspots and ambient audio', () {
      final scene = SceneAnnotationModel.fromMap({
        'paragraphIndex': 0,
        'ambientAudioAsset': 'assets/audio/ambience/forest.mp3',
        'hotspots': [
          {
            'id': 'mayon-volcano',
            'title': 'Mount Mayon',
            'description': 'A volcano in Albay.',
            'positionX': 0.55,
            'positionY': 0.26,
            'vocabularyIds': ['mayon-ch3-erupts'],
            'category': 'location',
          },
        ],
      });

      expect(scene.ambientAudioAsset, 'assets/audio/ambience/forest.mp3');
      expect(scene.hotspots.single.id, 'mayon-volcano');
      expect(scene.hotspots.single.vocabularyIds, ['mayon-ch3-erupts']);
      expect(scene.toMap()['hotspots'], [
        {
          'id': 'mayon-volcano',
          'title': 'Mount Mayon',
          'description': 'A volcano in Albay.',
          'positionX': 0.55,
          'positionY': 0.26,
          'vocabularyIds': ['mayon-ch3-erupts'],
          'category': 'location',
        },
      ]);
    });
  });

  test('story discovery tracking persists unique IDs locally', () async {
    final tracker = StoryDiscoveryTracker();
    await tracker.markDiscovered('mayon/mayon-magayon');
    await tracker.markDiscovered('mayon/mayon-magayon');
    await tracker.markDiscovered('ibalong/ibalong-baltog');

    final restored = await StoryDiscoveryTracker().getDiscoveredIds();
    expect(restored, {'mayon/mayon-magayon', 'ibalong/ibalong-baltog'});
  });

  test('vocabulary model preserves an optional recorded pronunciation', () {
    final hint = VocabHintModel.fromMap({
      'vocabularyId': 'mayon-ch1-marhay',
      'word': 'marhay',
      'definition': 'Good or beautiful.',
      'audioAsset': 'assets/audio/bikol/marhay.mp3',
    });

    expect(hint.audioAsset, 'assets/audio/bikol/marhay.mp3');
    expect(hint.toMap()['audioAsset'], 'assets/audio/bikol/marhay.mp3');
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

  testWidgets('pronunciation uses the recorded vocabulary asset first', (
    tester,
  ) async {
    final pronunciation = _FakeVocabularyPronunciationService();
    final hint = VocabHintModel(
      vocabularyId: 'mayon-ch1-marhay',
      word: 'marhay',
      definition: 'Good or beautiful.',
      audioAsset: 'assets/audio/bikol/marhay.mp3',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryVocabularyCard(
            hint: hint,
            languageCode: 'bik',
            exampleSentence: '',
            onClose: () {},
            pronunciationService: pronunciation,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Pronounce word'));
    await tester.pump();

    expect(pronunciation.word, 'marhay');
    expect(pronunciation.languageCode, 'bik');
    expect(pronunciation.audioAsset, 'assets/audio/bikol/marhay.mp3');
    expect(find.text('Playing'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop pronunciation'));
    await tester.pump();
    expect(pronunciation.stopCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await pronunciation.dispose();
  });

  testWidgets('scene cards use artwork before loading GIF media', (
    tester,
  ) async {
    const gifPath = 'assets/gifs/mayon/eruption.gif';
    const scene = SceneAnnotationModel(
      paragraphIndex: 0,
      assetKey: 'assets/scenes/volcano_eruption.json',
      gifAsset: gifPath,
      imageAssetKey: 'assets/images/mayon/eruption.svg',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SceneArtwork(scene: scene, height: 200, playAnimation: false),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == gifPath,
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scene viewer prioritizes GIF media when provided', (
    tester,
  ) async {
    const gifPath = 'assets/gifs/mayon/eruption.gif';
    const scene = SceneAnnotationModel(
      paragraphIndex: 0,
      assetKey: 'assets/scenes/volcano_eruption.json',
      gifAsset: gifPath,
      imageAssetKey: 'assets/images/mayon/eruption.svg',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SceneArtwork(scene: scene, height: 200, playAnimation: true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == gifPath,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
      vocabularyContext: 'triumph means a great victory.',
      educationalNote: 'Ibalong is an ancient Bikol epic.',
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
    expect(find.text('triumph means a great victory.'), findsOneWidget);
    expect(find.text('Ibalong is an ancient Bikol epic.'), findsOneWidget);
    expect(find.text('Return to Reading'), findsOneWidget);

    await tester.tap(find.text('Return to Reading'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Baltog Faces Tandayag'), findsOneWidget);
    expect(controller.offset, 350);
    controller.dispose();
  });

  testWidgets('scene hotspots open learning cards and link vocabulary', (
    tester,
  ) async {
    final tracker = StoryDiscoveryTracker();
    const hotspot = SceneHotspotModel(
      id: 'mayon-magayon',
      title: 'Magayon',
      description: "Makusog's daughter, remembered for her kindness.",
      positionX: 0.43,
      positionY: 0.45,
      category: 'character',
      role: "Chieftain's daughter",
      imageAsset: 'assets/images/mayon/magayon_introduction.svg',
      vocabularyIds: ['mayon-ch1-grace'],
      educationalNote: 'Magayon means beautiful in Bikol.',
    );
    final hint = VocabHintModel(
      vocabularyId: 'mayon-ch1-grace',
      word: 'grace',
      definition: 'Elegant movement or manner.',
      englishTranslation: 'grace',
      tagalogTranslation: 'grasya',
    );
    const scene = SceneAnnotationModel(
      paragraphIndex: 0,
      title: 'Meet Magayon',
      description: 'A story begins in Bikol.',
      imageAssetKey: 'assets/images/mayon/magayon_introduction.svg',
      hotspots: [hotspot],
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: ChapterSceneWidget(
            scene: scene,
            storyTitle: 'The Legend of Mount Mayon',
            heroTag: 'scene-mayon-discovery',
            storyId: 'mayon',
            languageCode: 'en',
            vocabularyHints: [hint],
            discoveryTracker: tracker,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Meet Magayon'));
    await tester.pump();

    expect(find.byTooltip('Magayon'), findsOneWidget);
    expect(find.byTooltip('Play ambience'), findsNothing);
    await tester.tap(find.byTooltip('Magayon'));
    await tester.pump();

    expect(find.text("Chieftain's daughter"), findsOneWidget);
    expect(find.text('Magayon means beautiful in Bikol.'), findsOneWidget);
    expect(await tracker.getDiscoveredIds(), contains('mayon/mayon-magayon'));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pump();
    await tester.tap(find.text('grace'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byTooltip('Pronounce word'), findsOneWidget);
    expect(find.text('grasya'), findsOneWidget);
  });

  test('AR content is derived from the Mayon scene and hotspot', () {
    const hotspot = SceneHotspotModel(
      id: 'mayon-volcano',
      title: 'Mount Mayon',
      description: 'The legend connects the volcano to Magayon.',
      positionX: 0.53,
      positionY: 0.45,
      category: 'location',
      imageAsset: 'assets/images/mayon/eruption.svg',
      educationalNote: 'Mayon is an active volcano in Albay.',
    );
    const scene = SceneAnnotationModel(
      paragraphIndex: 3,
      title: 'The Volcano Erupts',
      description: 'The legend says Magayon weeps for her lost love.',
      sceneType: 'volcano',
      imageAssetKey: 'assets/images/mayon/eruption.svg',
      hotspots: [hotspot],
    );

    final content = ArContentModel.fromScene(
      scene: scene,
      storyId: 'mayon',
      hotspot: scene.hotspots.single,
    );

    expect(content.id, 'mayon-ar-explorer');
    expect(content.storyId, 'mayon');
    expect(content.title, 'Mount Mayon');
    expect(content.description, hotspot.description);
    expect(content.imageAsset, hotspot.imageAsset);
    expect(content.educationalNote, hotspot.educationalNote);
  });

  test('Mayon AR billboard is self-contained glTF 2.0', () async {
    final bytes = await rootBundle.load('assets/models/mayon_billboard.gltf');
    final model = jsonDecode(
      utf8.decode(bytes.buffer.asUint8List()),
    ) as Map<String, dynamic>;
    final buffer =
        (model['buffers'] as List<dynamic>).single as Map<String, dynamic>;
    final uri = buffer['uri'] as String;

    expect(model['asset']['version'], '2.0');
    expect(uri, startsWith('data:application/octet-stream;base64,'));
    expect(
      base64Decode(uri.substring(uri.indexOf(',') + 1)).length,
      buffer['byteLength'],
    );
    expect(
      (model['meshes'] as List<dynamic>).single['primitives'].length,
      greaterThan(1),
    );
  });

  testWidgets('AR entry is limited to supported Mayon volcano scenes', (
    tester,
  ) async {
    const scene = SceneAnnotationModel(
      paragraphIndex: 3,
      title: 'The Volcano Erupts',
      sceneType: 'volcano',
      imageAssetKey: 'assets/images/mayon/eruption.svg',
    );
    final availability = _FakeArAvailabilityService(supported: true);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: ChapterSceneWidget(
            scene: scene,
            storyTitle: 'The Legend of Mount Mayon',
            heroTag: 'ar-mayon-scene',
            storyId: 'mayon',
            arAvailabilityService: availability,
          ),
        ),
      ),
    );
    await tester.tap(find.text('The Volcano Erupts'));
    await tester.pumpAndSettle();

    expect(find.text('Explore in AR'), findsOneWidget);
    expect(availability.checkCount, 1);
  });

  testWidgets('AR entry is not advertised for other stories', (tester) async {
    const scene = SceneAnnotationModel(
      paragraphIndex: 3,
      title: 'The Volcano Erupts',
      sceneType: 'volcano',
      imageAssetKey: 'assets/images/mayon/eruption.svg',
    );
    final availability = _FakeArAvailabilityService(supported: true);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: ChapterSceneWidget(
            scene: scene,
            storyTitle: 'The Heroes of Ibalong',
            heroTag: 'ar-not-ibalong',
            storyId: 'ibalong',
            arAvailabilityService: availability,
          ),
        ),
      ),
    );
    await tester.tap(find.text('The Volcano Erupts'));
    await tester.pumpAndSettle();

    expect(find.text('Explore in AR'), findsNothing);
    expect(availability.checkCount, 0);
  });

  testWidgets('unsupported AR offers a way back to the reader', (tester) async {
    final availability = _FakeArAvailabilityService(supported: false);
    final tracker = StoryDiscoveryTracker();
    const content = ArContentModel(
      id: 'mayon-ar-explorer',
      title: 'Mount Mayon',
      description: 'A volcano in Albay.',
      imageAsset: 'assets/images/mayon/eruption.svg',
      storyId: 'mayon',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: const Center(child: Text('Reader')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ArExplorerScreen(
                    content: content,
                    discoveryTracker: tracker,
                    availabilityService: availability,
                    onReturnToReader: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              child: const Icon(Icons.view_in_ar),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('AR not supported on this device.'), findsOneWidget);
    await tester.tap(find.text('Return to Reader'));
    await tester.pumpAndSettle();
    expect(find.text('Reader'), findsOneWidget);
  });

  testWidgets('AR fallback returns to the reader without changing its route', (
    tester,
  ) async {
    const scene = SceneAnnotationModel(
      paragraphIndex: 3,
      title: 'The Volcano Erupts',
      description: 'The legend remembers Magayon.',
      sceneType: 'volcano',
      imageAssetKey: 'assets/images/mayon/eruption.svg',
    );
    final availability = _FakeArAvailabilityService(
      supported: false,
      results: [true, false],
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: Column(
            children: [
              const Text('Reader'),
              Expanded(
                child: ChapterSceneWidget(
                  scene: scene,
                  storyTitle: 'The Legend of Mount Mayon',
                  heroTag: 'ar-return-reader',
                  storyId: 'mayon',
                  arAvailabilityService: availability,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('The Volcano Erupts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore in AR'));
    await tester.pumpAndSettle();
    expect(find.text('AR not supported on this device.'), findsOneWidget);

    await tester.tap(find.text('Return to Reader'));
    await tester.pumpAndSettle();

    expect(find.text('Reader'), findsOneWidget);
    expect(find.text('Explore in AR'), findsNothing);
    expect(availability.checkCount, 2);
  });

  testWidgets(
    'story codex hides undiscovered details and shows unlocked cards',
    (tester) async {
      final tracker = StoryDiscoveryTracker();
      await tracker.markDiscovered('mayon/mayon-magayon');

      await tester.pumpWidget(
        MaterialApp(
          home: StoryCodexScreen(
            storyId: 'mayon',
            languageCode: 'en',
            discoveryTracker: tracker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Story Codex'), findsOneWidget);
      expect(find.text('Magayon'), findsOneWidget);
      expect(find.text("Chieftain's daughter"), findsOneWidget);
      expect(find.text('Chief Makusog'), findsOneWidget);
      expect(find.text('Discover in Mayon to unlock'), findsWidgets);
    },
  );

  testWidgets('scene viewer uses static art when reduced motion is enabled', (
    tester,
  ) async {
    const scene = SceneAnnotationModel(
      paragraphIndex: 0,
      assetKey: 'assets/scenes/volcano_eruption.json',
      gifAsset: 'assets/gifs/mayon/eruption.gif',
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
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/gifs/mayon/eruption.gif',
      ),
      findsNothing,
    );
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
    const gifAssets = [
      'assets/gifs/mayon/eruption.gif',
      'assets/gifs/ibalong/monster_battle.gif',
    ];

    for (final asset in gifAssets) {
      final bytes = (await rootBundle.load(asset)).buffer.asUint8List();
      expect(bytes.take(6), [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);
    }

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

class _FakeVocabularyPronunciationService
    implements VocabularyPronunciationService {
  final StreamController<VocabularyPlaybackState> _states =
      StreamController<VocabularyPlaybackState>.broadcast(sync: true);

  String? word;
  String? languageCode;
  String? audioAsset;
  int stopCount = 0;

  @override
  Stream<VocabularyPlaybackState> get playbackStates => _states.stream;

  @override
  Future<void> pronounce({
    required String word,
    required String languageCode,
    String? audioAsset,
  }) async {
    this.word = word;
    this.languageCode = languageCode;
    this.audioAsset = audioAsset;
    _states.add(VocabularyPlaybackState.loading);
    _states.add(VocabularyPlaybackState.playing);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _states.add(VocabularyPlaybackState.idle);
  }

  @override
  Future<void> dispose() => _states.close();
}

class _FakeArAvailabilityService implements ArAvailabilityService {
  _FakeArAvailabilityService({
    required this.supported,
    this._results = const [],
  });

  final bool supported;
  final List<bool> _results;
  int checkCount = 0;

  @override
  Future<bool> isSupported() async {
    checkCount++;
    if (_results.isNotEmpty) return _results.removeAt(0);
    return supported;
  }
}
