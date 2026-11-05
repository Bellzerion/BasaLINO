import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/models/chapter_journey_model.dart';
import '../../../core/models/chapter_translation_model.dart';
import '../../../l10n/app_localizations_context.dart';

class ChapterClearedScreen extends ConsumerStatefulWidget {
  const ChapterClearedScreen({super.key, required this.journey});

  final ChapterJourney? journey;

  @override
  ConsumerState<ChapterClearedScreen> createState() =>
      _ChapterClearedScreenState();
}

class _ChapterClearedScreenState extends ConsumerState<ChapterClearedScreen> {
  Future<ChapterTranslationModel?>? _translationFuture;
  String? _translationLanguage;

  String _fallbackChapterTitle(String chapterId) {
    final chapterNumber = int.tryParse(
      RegExp(r'ch(\d+)$').firstMatch(chapterId)?.group(1) ?? '',
    );
    return context.l10n.chapterLabel(chapterNumber ?? 1);
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;
    if (journey == null || !journey.quizResult.passed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.chapterJourneyUnavailable),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/library'),
                  child: Text(context.l10n.continueAdventure),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final language = ref.watch(appLanguageProvider);
    if (_translationFuture == null || _translationLanguage != language) {
      _translationLanguage = language;
      _translationFuture = ref
          .read(storyRepositoryProvider)
          .getChapterTranslation(
            chapterId: journey.chapterId,
            languageCode: language,
          );
    }

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ChapterTranslationModel?>(
          future: _translationFuture,
          builder: (context, snapshot) {
            final title = snapshot.data?.title;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 104,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.chapterCleared,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF075C31),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title == null || title.isEmpty
                          ? _fallbackChapterTitle(journey.chapterId)
                          : title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1EB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFBFDAD0)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            context.l10n.greatJob,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF164D36),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.youUnderstoodTheStory,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.quizScore(
                              journey.quizResult.correctAnswers,
                              journey.quizResult.totalQuestions,
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.challengeXpEarned(
                              journey.quizResult.xpAwarded,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF9A5A00),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Card(
                      color: const Color(0xFFFFF8E7),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              context.l10n.bonusVocabularyChallenge,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF78350F),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(context.l10n.vocabularyBonusDescription),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => context.push(
                                '/vocabulary/${journey.chapterId}/challenge',
                                extra: journey,
                              ),
                              icon: const Icon(Icons.menu_book_rounded),
                              label: Text(
                                context.l10n.startVocabularyChallenge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.l10n.readyForNextAdventure,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.go(journey.continueLocation),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          context.l10n.continueAdventure,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
