import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/models/chapter_translation_model.dart';
import '../../../core/models/scene_annotation_model.dart';
import '../../../core/models/vocab_hint_model.dart';
import '../../../core/services/progress_repository.dart';
import '../../../l10n/app_localizations_context.dart';
import '../widgets/chapter_scene_widget.dart';
import '../widgets/vocabulary_card.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.storyId,
    required this.chapterId,
  });

  final String storyId;
  final String chapterId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  double _fontSize = 17.0;
  final ScrollController _readingController = ScrollController();
  Timer? _readingSaveTimer;
  ProgressRepository? _progressRepository;
  String? _readingUserId;
  String? _restoringReadingKey;
  bool _isRestoringReadingPosition = false;
  bool _hasShownSceneDiscoveryPrompt = false;
  Future<ChapterTranslationModel?>? _chapterTranslationFuture;
  Object? _chapterTranslationRepository;
  String? _chapterTranslationKey;
  VocabHintModel? _activeVocabularyHint;
  String? _activeVocabularyExample;
  String _activeVocabularyLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _readingController.addListener(_scheduleReadingPositionSave);
  }

  @override
  void dispose() {
    _readingSaveTimer?.cancel();
    if (_readingController.hasClients) {
      unawaited(_saveReadingPosition());
    }
    _readingController
      ..removeListener(_scheduleReadingPositionSave)
      ..dispose();
    super.dispose();
  }

  void _reportReadingStorageError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'reader progress persistence',
      ),
    );
  }

  void _restoreReadingPosition(String userId) {
    final key = '$userId/${widget.storyId}/${widget.chapterId}';
    if (_restoringReadingKey == key) return;
    _restoringReadingKey = key;
    _readingUserId = userId;
    final progressRepository = ref.read(progressRepositoryProvider);
    _progressRepository = progressRepository;
    _isRestoringReadingPosition = true;

    unawaited(() async {
      try {
        final savedPosition = await progressRepository.getReadingPosition(
          userId: userId,
          storyId: widget.storyId,
          chapterId: widget.chapterId,
        );
        if (!mounted || _restoringReadingKey != key) return;
        if (savedPosition != null) {
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted || !_readingController.hasClients) return;
          final maxExtent = _readingController.position.maxScrollExtent;
          _readingController.jumpTo(savedPosition.clamp(0, maxExtent));
        }
        _isRestoringReadingPosition = false;
      } catch (error, stackTrace) {
        _isRestoringReadingPosition = false;
        _reportReadingStorageError(error, stackTrace);
      }
    }());
  }

  void _scheduleReadingPositionSave() {
    if (_isRestoringReadingPosition ||
        !_readingController.hasClients ||
        _progressRepository == null ||
        _readingUserId == null) {
      return;
    }
    _readingSaveTimer?.cancel();
    _readingSaveTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_saveReadingPosition());
    });
  }

  Future<void> _saveReadingPosition() async {
    final repository = _progressRepository;
    final userId = _readingUserId;
    if (repository == null ||
        userId == null ||
        !_readingController.hasClients) {
      return;
    }

    try {
      await ref
          .read(progressMutationServiceProvider)
          .saveReadingPosition(
            userId: userId,
            storyId: widget.storyId,
            chapterId: widget.chapterId,
            position: _readingController.offset,
          );
    } catch (error, stackTrace) {
      _reportReadingStorageError(error, stackTrace);
    }
  }

  void _showVocabularyCard(
    VocabHintModel hint, {
    required String languageCode,
    required String exampleSentence,
  }) {
    setState(() {
      _activeVocabularyHint = hint;
      _activeVocabularyLanguage = languageCode;
      _activeVocabularyExample = hint.exampleSentence ?? exampleSentence;
    });
  }

  String _exampleSentence(String paragraph, RegExpMatch match) {
    final start = paragraph.lastIndexOf(
      RegExp(r'[.!?]'),
      match.start > 0 ? match.start - 1 : 0,
    );
    final punctuation = paragraph.indexOf(RegExp(r'[.!?]'), match.end);
    final end = punctuation == -1 ? paragraph.length : punctuation + 1;
    return paragraph
        .substring(start == -1 ? 0 : start + 1, end)
        .replaceAll(RegExp(r'\[([^\]]+)\]'), r'$1')
        .trim();
  }

  List<TextSpan> _buildInteractiveParagraph(
    String content,
    List<VocabHintModel> hints,
    String languageCode,
  ) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\[([^\]]+)\]');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(content)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: content.substring(lastMatchEnd, match.start),
            style: TextStyle(
              fontSize: _fontSize,
              color: const Color(0xFF1F2937),
              height: 1.65,
            ),
          ),
        );
      }

      final bracketedWord = match.group(1)!;
      final matchedHint = hints.firstWhere(
        (h) => h.word.toLowerCase() == bracketedWord.toLowerCase(),
        orElse: () => VocabHintModel(
          vocabularyId: 'legacy:${bracketedWord.toLowerCase()}',
          word: bracketedWord,
          definition: context.l10n.readerFallbackVocabularyDefinition,
        ),
      );

      spans.add(
        TextSpan(
          text: bracketedWord,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFD97706),
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: const Color(0xFFD97706),
            height: 1.65,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _showVocabularyCard(
              matchedHint,
              languageCode: languageCode,
              exampleSentence: _exampleSentence(content, match),
            ),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(lastMatchEnd),
          style: TextStyle(
            fontSize: _fontSize,
            color: const Color(0xFF1F2937),
            height: 1.65,
          ),
        ),
      );
    }

    return spans;
  }

  /// Splits [trans.content] on double-newlines into individual paragraphs,
  /// then interleaves [ChapterSceneWidget]s wherever a [SceneAnnotationModel]
  /// specifies a [paragraphIndex].
  List<Widget> _buildReaderContent(ChapterTranslationModel trans) {
    final paragraphs = trans.content
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    // Keep multiple story moments at the same paragraph boundary.
    final sceneMap = <int, List<SceneAnnotationModel>>{};
    for (final scene in trans.scenes) {
      sceneMap.putIfAbsent(scene.paragraphIndex, () => []).add(scene);
    }

    final widgets = <Widget>[];
    var hasSceneInThisBuild = false;

    for (int i = 0; i < paragraphs.length; i++) {
      // Add the paragraph text.
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
            text: TextSpan(
              children: _buildInteractiveParagraph(
                paragraphs[i],
                trans.vocabularyHints,
                trans.languageCode,
              ),
            ),
          ),
        ),
      );

      // After this paragraph, inject a scene card if one is configured.
      for (final scene in sceneMap[i] ?? const <SceneAnnotationModel>[]) {
        final sceneKey = 'scene_${trans.chapterId}_$i-${widgets.length}';
        widgets.add(
          ChapterSceneWidget(
            key: ValueKey(sceneKey),
            scene: scene,
            storyTitle: trans.title,
            heroTag: sceneKey,
            showExplorePrompt:
                !_hasShownSceneDiscoveryPrompt && !hasSceneInThisBuild,
            onExplorePromptShown: _markSceneDiscoveryPromptShown,
          ),
        );
        hasSceneInThisBuild = true;
      }
    }

    final trailingScenes =
        sceneMap.entries
            .where((entry) => entry.key >= paragraphs.length)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in trailingScenes) {
      for (final scene in entry.value) {
        final sceneKey =
            'scene_${trans.chapterId}_${entry.key}-${widgets.length}';
        widgets.add(
          ChapterSceneWidget(
            key: ValueKey(sceneKey),
            scene: scene,
            storyTitle: trans.title,
            heroTag: sceneKey,
            showExplorePrompt:
                !_hasShownSceneDiscoveryPrompt && !hasSceneInThisBuild,
            onExplorePromptShown: _markSceneDiscoveryPromptShown,
          ),
        );
        hasSceneInThisBuild = true;
      }
    }

    return widgets;
  }

  void _markSceneDiscoveryPromptShown() {
    if (!mounted || _hasShownSceneDiscoveryPrompt) return;
    _hasShownSceneDiscoveryPrompt = true;
  }

  @override
  Widget build(BuildContext context) {
    final storyRepo = ref.watch(storyRepositoryProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final userId = ref.watch(currentUserProvider)?.uid ?? 'guest';
    final translationKey = '${widget.storyId}/${widget.chapterId}/$currentLang';
    if (_chapterTranslationFuture == null ||
        _chapterTranslationKey != translationKey ||
        !identical(_chapterTranslationRepository, storyRepo)) {
      _chapterTranslationKey = translationKey;
      _chapterTranslationRepository = storyRepo;
      _chapterTranslationFuture = storyRepo.getChapterTranslation(
        chapterId: widget.chapterId,
        languageCode: currentLang,
      );
    }
    final chapterTranslationFuture = _chapterTranslationFuture!;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.readerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: context.l10n.readerAdjustTextSize,
            onPressed: () {
              setState(() {
                _fontSize = _fontSize >= 22.0 ? 15.0 : _fontSize + 2.0;
              });
            },
          ),
          PopupMenuButton<String>(
            tooltip: context.l10n.readerSelectLanguage,
            icon: const Icon(Icons.language),
            initialValue: currentLang,
            onSelected: (code) {
              setState(() {
                _activeVocabularyHint = null;
                _activeVocabularyExample = null;
              });
              ref.read(appLanguageProvider.notifier).state = code;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Text(context.l10n.readerLanguageEnglish),
              ),
              PopupMenuItem(
                value: 'tl',
                child: Text(context.l10n.readerLanguageTagalog),
              ),
              PopupMenuItem(
                value: 'bik',
                child: Text(context.l10n.readerLanguageBikol),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<ChapterTranslationModel?>(
              future: chapterTranslationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(context.l10n.readerUnavailable),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(appLanguageProvider.notifier).state =
                                    'en',
                            child: Text(context.l10n.readerReadInEnglish),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final trans = snapshot.data!;
                _restoreReadingPosition(userId);

                return SingleChildScrollView(
                  controller: _readingController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (trans.needsReview)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Color(0xFF92400E),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.l10n.readerTranslationReview,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        trans.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ── Story content: paragraphs interleaved with scene cards ──
                      ...(_buildReaderContent(trans)),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/challenge/${widget.storyId}/${widget.chapterId}',
                        ),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: Text(context.l10n.readerCheckKnowledge),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_activeVocabularyHint != null)
            VocabularyCardOverlay(
              key: ValueKey(_activeVocabularyHint!.vocabularyId),
              hint: _activeVocabularyHint!,
              languageCode: _activeVocabularyLanguage,
              exampleSentence: _activeVocabularyExample ?? '',
              onClose: () {
                if (!mounted) return;
                setState(() {
                  _activeVocabularyHint = null;
                  _activeVocabularyExample = null;
                });
              },
            ),
        ],
      ),
    );
  }
}
