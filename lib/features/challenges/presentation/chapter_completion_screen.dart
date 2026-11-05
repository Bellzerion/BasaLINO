import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/chapter_journey_model.dart';
import '../../../l10n/app_localizations_context.dart';

class ChapterCompletionScreen extends ConsumerStatefulWidget {
  const ChapterCompletionScreen({super.key, required this.journey});

  final ChapterJourney? journey;

  @override
  ConsumerState<ChapterCompletionScreen> createState() =>
      _ChapterCompletionScreenState();
}

class _ChapterCompletionScreenState
    extends ConsumerState<ChapterCompletionScreen> {
  Future<List<ChapterModel>>? _progressFuture;
  String? _progressUserId;

  @override
  Widget build(BuildContext context) {
    final chapterJourney = widget.journey;
    if (chapterJourney == null) {
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

    final result = chapterJourney.quizResult;
    final userId = ref.watch(currentUserProvider)?.uid ?? 'guest';
    if (_progressFuture == null || _progressUserId != userId) {
      _progressUserId = userId;
      _progressFuture = ref
          .read(progressRepositoryProvider)
          .getChaptersWithStatus(
            storyId: chapterJourney.storyId,
            userId: userId,
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          result.passed
              ? context.l10n.chapterComplete
              : context.l10n.chapterPracticeComplete,
        ),
      ),
      body: FutureBuilder<List<ChapterModel>>(
        future: _progressFuture,
        builder: (context, snapshot) {
          final chapters = snapshot.data;
          final completed = chapters
              ?.where((chapter) => chapter.isCompleted)
              .length;
          final total = chapters?.length;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    result.passed
                        ? Icons.emoji_events_rounded
                        : Icons.auto_stories_rounded,
                    size: 76,
                    color: const Color(0xFFD97706),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.passed
                        ? context.l10n.chapterComplete
                        : context.l10n.chapterPracticeComplete,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF164D36),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _JourneyCheck(
                    complete: true,
                    label: context.l10n.storyQuizComplete,
                  ),
                  const SizedBox(height: 12),
                  _JourneyCheck(
                    complete: chapterJourney.vocabularyCompleted,
                    label: chapterJourney.vocabularyCompleted
                        ? context.l10n.vocabularyChallengeComplete
                        : context.l10n.vocabularySkipped,
                  ),
                  const SizedBox(height: 20),
                  _JourneyStat(
                    icon: Icons.stars_rounded,
                    label: context.l10n.xpEarned,
                    value: '+${result.xpAwarded}',
                  ),
                  const SizedBox(height: 10),
                  _JourneyStat(
                    icon: Icons.menu_book_rounded,
                    label: context.l10n.wordsPracticedLabel,
                    value: '${chapterJourney.wordsPracticed}',
                  ),
                  const SizedBox(height: 10),
                  _JourneyStat(
                    icon: Icons.flag_rounded,
                    label: context.l10n.chapterProgress,
                    value: snapshot.hasError
                        ? context.l10n.chapterProgressUnavailable
                        : completed == null || total == null
                        ? '…'
                        : context.l10n.chapterProgressCount(completed, total),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      final isFinalChapter =
                          result.passed && result.nextChapterId == null;
                      context.go(
                        isFinalChapter
                            ? '/story-completion/${chapterJourney.storyId}'
                            : '/story/${chapterJourney.storyId}',
                      );
                    },
                    child: Text(context.l10n.continueAdventure),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JourneyCheck extends StatelessWidget {
  const _JourneyCheck({required this.complete, required this.label});

  final bool complete;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: complete ? const Color(0xFF07804B) : const Color(0xFF9CA3AF),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _JourneyStat extends StatelessWidget {
  const _JourneyStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F5E9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF075C31)),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
