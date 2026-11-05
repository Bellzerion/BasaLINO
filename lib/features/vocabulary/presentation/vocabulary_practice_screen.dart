import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/models/chapter_journey_model.dart';
import '../../../core/models/chapter_translation_model.dart';
import '../../../core/models/vocab_hint_model.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/services/local_progress_repository.dart';
import '../../../l10n/app_localizations_context.dart';

/// A recall bonus that never changes quiz results or chapter progression.
class VocabularyPracticeScreen extends ConsumerStatefulWidget {
  const VocabularyPracticeScreen({
    super.key,
    required this.chapterId,
    this.journey,
  });

  final String chapterId;
  final ChapterJourney? journey;

  @override
  ConsumerState<VocabularyPracticeScreen> createState() =>
      _VocabularyPracticeScreenState();
}

class _VocabularyPracticeScreenState
    extends ConsumerState<VocabularyPracticeScreen> {
  int _index = 0;
  String? _selectedWord;
  bool? _wasCorrect;
  List<VocabHintModel>? _items;
  Future<int>? _bonusFuture;
  final Map<String, List<VocabHintModel>> _optionsByWord = {};

  void _prepare(ChapterTranslationModel translation) {
    _items ??= [...translation.vocabularyHints]..shuffle(Random());
    for (final item in _items!) {
      _optionsByWord.putIfAbsent(item.word, () {
        final options = [
          item,
          ..._items!.where((hint) => hint.word != item.word),
        ]..shuffle(Random());
        final choices = options.take(3).toList();
        if (!choices.contains(item)) choices[0] = item;
        return choices..shuffle(Random());
      });
    }
  }

  Future<void> _submit(VocabHintModel item) async {
    if (_selectedWord == null || _wasCorrect != null) return;
    final correct = _selectedWord == item.word;
    final repository = ref.read(progressRepositoryProvider);
    if (repository is LocalProgressRepository) {
      await repository.recordVocabularyActivity(
        userId: ref.read(currentUserProvider)?.uid ?? 'guest',
        chapterId: widget.chapterId,
        languageCode: ref.read(appLanguageProvider),
        word: item.word,
        activityType: 'recall_challenge',
        correct: correct,
      );
    }
    if (mounted) setState(() => _wasCorrect = correct);
  }

  void _next() => setState(() {
    _selectedWord = null;
    _wasCorrect = null;
    _index++;
  });

  String _contextSentence(
    ChapterTranslationModel translation,
    VocabHintModel item,
  ) {
    final marker = '[${item.word}]';
    final start = translation.content.lastIndexOf(
      '.',
      translation.content.indexOf(marker),
    );
    final end = translation.content.indexOf(
      '.',
      translation.content.indexOf(marker),
    );
    if (start >= 0 && end > start) {
      return translation.content
          .substring(start + 1, end + 1)
          .replaceAll(marker, item.word)
          .trim();
    }
    return item.word;
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(appLanguageProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.knowledgeVocabularyChallenge)),
      body: FutureBuilder<ChapterTranslationModel?>(
        future: ref
            .read(storyRepositoryProvider)
            .getChapterTranslation(
              chapterId: widget.chapterId,
              languageCode: languageCode,
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final translation = snapshot.data;
          if (translation == null || translation.vocabularyHints.isEmpty) {
            return _unavailableView(context);
          }
          _prepare(translation);
          if (_index >= _items!.length) return _completeView(context);
          return _challengeView(context, translation, _items![_index]);
        },
      ),
    );
  }

  Widget _challengeView(
    BuildContext context,
    ChapterTranslationModel translation,
    VocabHintModel item,
  ) {
    final options = _optionsByWord[item.word]!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_index + 1} / ${_items!.length}',
            style: const TextStyle(color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.vocabularyWhatDoesWordMean(item.word),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(context.l10n.vocabularyChallengePrompt),
          const SizedBox(height: 20),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: _wasCorrect == null
                    ? () => setState(() => _selectedWord = option.word)
                    : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectedWord == option.word
                      ? const Color(0xFFD8EAE1)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(option.definition),
                  ),
                ),
              ),
            ),
          ),
          if (_wasCorrect == null) ...[
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedWord == null ? null : () => _submit(item),
              child: Text(context.l10n.vocabularySubmitAnswer),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              _wasCorrect!
                  ? context.l10n.vocabularyCorrectFeedback
                  : context.l10n.vocabularyIncorrectFeedback,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _wasCorrect!
                    ? const Color(0xFF075C31)
                    : Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(item.definition),
            const SizedBox(height: 8),
            Text(
              '“${_contextSentence(translation, item)}”',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _next,
              child: Text(context.l10n.vocabularyContinue),
            ),
          ],
        ],
      ),
    );
  }

  Future<int> _claimVocabularyBonus() async {
    final journey = widget.journey;
    if (journey == null || !journey.quizResult.passed) return 0;
    final awarded = await ref
        .read(authRepositoryProvider)
        .awardVocabularyBonus(chapterId: widget.chapterId);
    return awarded ? AuthRepository.vocabularyBonusXp : 0;
  }

  Widget _completeView(BuildContext context) {
    _bonusFuture ??= _claimVocabularyBonus();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<int>(
          future: _bonusFuture,
          builder: (context, snapshot) {
            final failed = snapshot.hasError;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 76,
                  color: Color(0xFF07804B),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.vocabularyChallengeComplete,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(context.l10n.wordsPracticed(_items!.length)),
                const SizedBox(height: 8),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const CircularProgressIndicator()
                else if (failed)
                  Column(
                    children: [
                      Text(
                        context.l10n.vocabularyBonusFailed,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _bonusFuture = null),
                        child: Text(context.l10n.vocabularyRetryBonus),
                      ),
                    ],
                  )
                else
                  Text(
                    context.l10n.bonusXpEarned(snapshot.data ?? 0),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A5A00),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      snapshot.connectionState == ConnectionState.waiting ||
                          failed
                      ? null
                      : () {
                          final journey = widget.journey;
                          if (journey == null) {
                            Navigator.of(context).pop();
                            return;
                          }
                          context.go(journey.continueLocation);
                        },
                  child: Text(context.l10n.continueAdventure),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _unavailableView(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.vocabularyUnavailable),
          if (widget.journey != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(widget.journey!.continueLocation),
              child: Text(context.l10n.continueAdventure),
            ),
          ],
        ],
      ),
    ),
  );
}
