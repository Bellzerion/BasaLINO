import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../core/models/chapter_translation_model.dart';
import '../../../core/models/vocab_hint_model.dart';
import '../../../core/services/local_progress_repository.dart';

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
  LocalProgressRepository? _localProgressRepository;
  String? _readingUserId;
  String? _restoringReadingKey;
  bool _isRestoringReadingPosition = false;

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
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'reader progress persistence',
    ));
  }

  void _restoreReadingPosition(String userId) {
    final key = '$userId/${widget.storyId}/${widget.chapterId}';
    if (_restoringReadingKey == key) return;
    _restoringReadingKey = key;
    _readingUserId = userId;
    final progressRepository = ref.read(progressRepositoryProvider);
    if (progressRepository is! LocalProgressRepository) return;
    _localProgressRepository = progressRepository;
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
        _localProgressRepository == null ||
        _readingUserId == null) {
      return;
    }
    _readingSaveTimer?.cancel();
    _readingSaveTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_saveReadingPosition());
    });
  }

  Future<void> _saveReadingPosition() async {
    final repository = _localProgressRepository;
    final userId = _readingUserId;
    if (repository == null || userId == null || !_readingController.hasClients) return;

    try {
      await repository.saveReadingPosition(
        userId: userId,
        storyId: widget.storyId,
        chapterId: widget.chapterId,
        position: _readingController.offset,
      );
    } catch (error, stackTrace) {
      _reportReadingStorageError(error, stackTrace);
    }
  }

  void _showVocabSheet(VocabHintModel hint) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hint.partOfSpeech?.toUpperCase() ?? 'VOCABULARY',
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hint.word,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hint.definition,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  List<TextSpan> _buildInteractiveParagraph(
    String content,
    List<VocabHintModel> hints,
  ) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\[([^\]]+)\]');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(content)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: content.substring(lastMatchEnd, match.start),
          style: TextStyle(
            fontSize: _fontSize,
            color: const Color(0xFF1F2937),
            height: 1.65,
          ),
        ));
      }

      final bracketedWord = match.group(1)!;
      final matchedHint = hints.firstWhere(
        (h) => h.word.toLowerCase() == bracketedWord.toLowerCase(),
        orElse: () => VocabHintModel(word: bracketedWord, definition: 'A key story vocabulary term.'),
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
            ..onTap = () => _showVocabSheet(matchedHint),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastMatchEnd),
        style: TextStyle(
          fontSize: _fontSize,
          color: const Color(0xFF1F2937),
          height: 1.65,
        ),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final storyRepo = ref.watch(storyRepositoryProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final userId = ref.watch(currentUserProvider)?.uid ?? 'guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Adjust text size',
            onPressed: () {
              setState(() {
                _fontSize = _fontSize >= 22.0 ? 15.0 : _fontSize + 2.0;
              });
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Select Language',
            icon: const Icon(Icons.language),
            initialValue: currentLang,
            onSelected: (code) {
              ref.read(appLanguageProvider.notifier).state = code;
              ref.read(authRepositoryProvider).updateLanguage(code);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'en', child: Text('English (EN)')),
              PopupMenuItem(value: 'tl', child: Text('Tagalog (TL)')),
              PopupMenuItem(value: 'bik', child: Text('Bikol (BIK)')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<ChapterTranslationModel?>(
        future: storyRepo.getChapterTranslation(
          chapterId: widget.chapterId,
          languageCode: currentLang,
        ),
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
                    const Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Chapter content unavailable in selected language.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(appLanguageProvider.notifier).state = 'en',
                      child: const Text('Read in English'),
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
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Color(0xFF92400E)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This translation is in review by language specialists.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
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
                RichText(
                  text: TextSpan(
                    children: _buildInteractiveParagraph(trans.content, trans.vocabularyHints),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/challenge/${widget.storyId}/${widget.chapterId}');
                  },
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Take Reading Check'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
