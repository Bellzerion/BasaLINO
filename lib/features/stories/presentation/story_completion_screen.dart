import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/story_model.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/services/local_auth_repository.dart';
import '../../../core/services/local_progress_repository.dart';
import '../../../l10n/app_localizations_context.dart';

class StoryCompletionScreen extends ConsumerStatefulWidget {
  const StoryCompletionScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<StoryCompletionScreen> createState() =>
      _StoryCompletionScreenState();
}

class _StoryCompletionScreenState extends ConsumerState<StoryCompletionScreen> {
  static const _gold = Color(0xFFF59E0B);
  static const _green = Color(0xFF07804B);

  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  Future<_StoryCompletionSummary?>? _summaryFuture;
  String? _summaryUserId;
  bool _celebrationStarted = false;
  bool _redirecting = false;

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<_StoryCompletionSummary?> _loadSummary(String userId) async {
    final storiesFuture = ref.read(storyRepositoryProvider).getStories();
    final progressRepository = ref.read(progressRepositoryProvider);
    final authRepository = ref.read(authRepositoryProvider);
    final chaptersFuture = progressRepository.getChaptersWithStatus(
      storyId: widget.storyId,
      userId: userId,
    );
    final attemptsFuture = progressRepository.getRecentAttempts(
      userId,
      limit: 10000,
    );
    final vocabularyBonusFuture = authRepository is LocalAuthRepository
        ? authRepository.getAwardedVocabularyBonusChapterIds(userId: userId)
        : Future<Set<String>>.value(const {});
    final vocabularyCountFuture = () async {
      if (progressRepository is! LocalProgressRepository) return 0;
      final chapters = await chaptersFuture;
      return progressRepository.getVocabularyWordsPracticedCount(
        userId: userId,
        chapterIds: chapters.map((chapter) => chapter.id).toSet(),
      );
    }();

    final stories = await storiesFuture;
    final chapters = await chaptersFuture;
    final attempts = await attemptsFuture;
    if (chapters.isEmpty || chapters.any((chapter) => !chapter.isCompleted)) {
      return null;
    }

    StoryModel? story;
    for (final item in stories) {
      if (item.id == widget.storyId) {
        story = item;
        break;
      }
    }
    if (story == null) return null;

    final chapterIds = chapters.map((chapter) => chapter.id).toSet();
    final vocabularyBonusChapterIds = await vocabularyBonusFuture;
    final storyAttempts = attempts
        .where((attempt) => chapterIds.contains(attempt.chapterId))
        .toList();
    final firstPassByChapter = <String, DateTime>{};
    for (final attempt in storyAttempts.where((attempt) => attempt.passed)) {
      final current = firstPassByChapter[attempt.chapterId];
      if (current == null || attempt.attemptedAt.isBefore(current)) {
        firstPassByChapter[attempt.chapterId] = attempt.attemptedAt;
      }
    }
    final completionDate = firstPassByChapter.length == chapters.length
        ? firstPassByChapter.values.reduce(
            (latest, date) => date.isAfter(latest) ? date : latest,
          )
        : null;

    return _StoryCompletionSummary(
      story: story,
      chapters: chapters,
      wordsPracticed: await vocabularyCountFuture,
      xpEarned:
          storyAttempts.fold(0, (total, attempt) => total + attempt.xpAwarded) +
          vocabularyBonusChapterIds.intersection(chapterIds).length *
              AuthRepository.vocabularyBonusXp,
      completionDate: completionDate,
    );
  }

  void _startCelebration() {
    if (_celebrationStarted || MediaQuery.of(context).disableAnimations) return;
    _celebrationStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confettiController.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.uid ?? 'guest';
    if (_summaryFuture == null || _summaryUserId != userId) {
      _summaryUserId = userId;
      _summaryFuture = _loadSummary(userId);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      body: SafeArea(
        child: FutureBuilder<_StoryCompletionSummary?>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final summary = snapshot.data;
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.errorGeneric,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go('/library'),
                        child: Text(context.l10n.storyCompletionReturnToMap),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (summary == null) {
              if (!_redirecting) {
                _redirecting = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) context.go('/story/${widget.storyId}');
                });
              }
              return const Center(child: CircularProgressIndicator());
            }

            _startCelebration();
            return Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CompletionHero(
                            title: context.l10n.storyCompletionTitle,
                            storyTitle: summary.story.titleEn,
                            message: context.l10n.storyCompletionMessage,
                          ),
                          const SizedBox(height: 20),
                          _CompletionStats(summary: summary),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => context.go('/library'),
                            icon: const Icon(Icons.map_rounded),
                            label: Text(
                              context.l10n.storyCompletionReturnToMap,
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              backgroundColor: const Color(0xFF075C31),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () =>
                                context.go('/story/${summary.story.id}'),
                            icon: const Icon(Icons.replay_rounded),
                            label: Text(context.l10n.storyCompletionReplay),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF075C31),
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 0.04,
                        numberOfParticles: 22,
                        maxBlastForce: 12,
                        minBlastForce: 5,
                        gravity: 0.2,
                        colors: const [_gold, _green],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StoryCompletionSummary {
  const _StoryCompletionSummary({
    required this.story,
    required this.chapters,
    required this.wordsPracticed,
    required this.xpEarned,
    required this.completionDate,
  });

  final StoryModel story;
  final List<ChapterModel> chapters;
  final int wordsPracticed;
  final int xpEarned;
  final DateTime? completionDate;
}

class _CompletionHero extends StatelessWidget {
  const _CompletionHero({
    required this.title,
    required this.storyTitle,
    required this.message,
  });

  final String title;
  final String storyTitle;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF075C31), Color(0xFF3C8068)],
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26075C31),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFCD34D), width: 2),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 54,
            color: Color(0xFFFCD34D),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          storyTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFE6A6),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _CompletionStats extends StatelessWidget {
  const _CompletionStats({required this.summary});

  final _StoryCompletionSummary summary;

  @override
  Widget build(BuildContext context) {
    final date = summary.completionDate;
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _CompletionStat(
              icon: Icons.menu_book_rounded,
              label: context.l10n.storyCompletionChapters,
              value: context.l10n.chapterProgressCount(
                summary.chapters.length,
                summary.chapters.length,
              ),
            ),
            const Divider(height: 24),
            _CompletionStat(
              icon: Icons.spellcheck_rounded,
              label: context.l10n.storyCompletionWordsPracticed,
              value: '${summary.wordsPracticed}',
            ),
            const Divider(height: 24),
            _CompletionStat(
              icon: Icons.stars_rounded,
              label: context.l10n.storyCompletionXpEarned,
              value: '${summary.xpEarned}',
            ),
            if (date != null) ...[
              const Divider(height: 24),
              _CompletionStat(
                icon: Icons.calendar_month_rounded,
                label: context.l10n.storyCompletionDate,
                value: MaterialLocalizations.of(context).formatMediumDate(date),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletionStat extends StatelessWidget {
  const _CompletionStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFF07804B), size: 24),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFF075C31),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}
