import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/models/chapter_journey_model.dart';
import '../../../core/models/challenge_model.dart';
import '../../../core/models/attempt_result_model.dart';
import '../../../core/models/progress_model.dart';
import '../../../core/services/local_progress_repository.dart';
import '../../../l10n/app_localizations_context.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.storyId,
    required this.chapterId,
  });

  final String storyId;
  final String chapterId;

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  final Map<String, String> _selectedAnswers = {};
  bool _isSubmitting = false;
  AttemptResultModel? _result;
  Future<ChallengeModel?>? _challengeFuture;
  String? _requestKey;
  String? _snapshotId;
  final _uuid = const Uuid();

  Future<ChallengeModel?> _prepareChallenge(String languageCode) async {
    final progressRepo = ref.read(progressRepositoryProvider);
    final userId = ref.read(currentUserProvider)?.uid ?? 'guest';
    final excluded = progressRepo is LocalProgressRepository
        ? await progressRepo.getRecentQuestionIds(
            userId: userId,
            chapterId: widget.chapterId,
            languageCode: languageCode,
          )
        : const <String>[];
    final challenge = await ref
        .read(challengeRepositoryProvider)
        .getChallenge(
          chapterId: widget.chapterId,
          languageCode: languageCode,
          excludedQuestionIds: excluded,
        );
    if (challenge != null && progressRepo is LocalProgressRepository) {
      _snapshotId = _uuid.v4();
      await progressRepo.startQuizSnapshot(
        userId: userId,
        snapshot: QuizAttemptSnapshot(
          id: _snapshotId!,
          bankId: challenge.id,
          bankVersion: challenge.version,
          chapterId: widget.chapterId,
          languageCode: challenge.languageCode,
          questionIds: challenge.questions
              .map((question) => question.id)
              .toList(),
          startedAt: DateTime.now(),
        ),
      );
    }
    return challenge;
  }

  Future<void> _submitQuiz(ChallengeModel challenge) async {
    if (_selectedAnswers.length < challenge.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.challengeIncompleteQuestions)),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final challengeRepo = ref.read(challengeRepositoryProvider);
      final res = await challengeRepo.submitAttempt(
        challengeId: challenge.id,
        chapterId: widget.chapterId,
        questionIds: challenge.questions
            .map((question) => question.id)
            .toList(),
        answers: _selectedAnswers,
      );

      final user = ref.read(currentUserProvider);
      final userId = user?.uid ?? 'guest';
      final progressRepo = ref.read(progressRepositoryProvider);

      if (progressRepo is LocalProgressRepository) {
        if (_snapshotId != null) {
          await progressRepo.completeQuizSnapshot(
            userId: userId,
            snapshotId: _snapshotId!,
            answers: _selectedAnswers,
          );
        }
        await progressRepo.recordAttemptAndUnlock(
          userId: userId,
          storyId: widget.storyId,
          chapterId: widget.chapterId,
          chapterTitle: 'Chapter ${widget.chapterId}',
          score: res.score,
          xpAwarded: res.xpAwarded,
          passed: res.passed,
          nextChapterId: res.nextChapterId,
        );
      }

      // Add XP to user profile
      if (res.xpAwarded > 0) {
        await ref.read(authRepositoryProvider).addXp(res.xpAwarded);
      }

      if (res.passed) {
        if (mounted) {
          context.go(
            '/chapter-cleared',
            extra: ChapterJourney(
              storyId: widget.storyId,
              chapterId: widget.chapterId,
              quizResult: res,
            ),
          );
        }
      } else {
        setState(() {
          _result = res;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.challengeSubmitFailed(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _startNewAttempt(String languageCode) {
    setState(() {
      _selectedAnswers.clear();
      _result = null;
      _snapshotId = null;
      _requestKey = '$languageCode/${widget.chapterId}';
      _challengeFuture = _prepareChallenge(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final requestKey = '$lang/${widget.chapterId}';
    if (_challengeFuture == null || _requestKey != requestKey) {
      _requestKey = requestKey;
      _challengeFuture = _prepareChallenge(lang);
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.challengeTitle)),
      body: FutureBuilder<ChallengeModel?>(
        future: _challengeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text(context.l10n.challengeUnavailable));
          }

          final challenge = snapshot.data!;

          if (_result != null) {
            return _buildResultView(_result!);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xE8E5F1EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        color: Color(0xFF075C31),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.l10n.challengeInstructions(
                            challenge.questions.length,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF164D36),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...challenge.questions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final q = entry.value;
                  return _buildQuestionCard(idx + 1, q);
                }),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitQuiz(challenge),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.l10n.challengeSubmit),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(int questionNum, ChallengeQuestionModel question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF3E8970),
                  child: Text(
                    '$questionNum',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...question.options.map((option) {
              final isSelected = _selectedAnswers[question.id] == option.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAnswers[question.id] = option.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD8EAE1)
                          : const Color(0xF9FFFDF7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF075C31)
                            : const Color(0xFFBFDAD0),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? const Color(0xFF075C31)
                              : const Color(0xFF78958A),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF164D36)
                                  : const Color(0xFF263B31),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(AttemptResultModel res) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              res.passed
                  ? Icons.emoji_events_rounded
                  : Icons.replay_circle_filled_rounded,
              size: 80,
              color: res.passed
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.quizComplete,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF065F46),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.quizScore(res.correctAnswers, res.totalQuestions),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: Color(0xFF4B5563)),
            ),
            if (!res.passed) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.challengeResultKeepPracticing,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.challengeXpEarned(res.xpAwarded),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
            ),
            if (!res.passed)
              OutlinedButton(
                onPressed: () =>
                    _startNewAttempt(ref.read(appLanguageProvider)),
                child: Text(context.l10n.challengeRetry),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go('/story/${widget.storyId}'),
              child: Text(context.l10n.challengeBackToChapters),
            ),
          ],
        ),
      ),
    );
  }
}
