import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/cloud_data_provider.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../core/config/auth_mode.dart';
import '../../../core/models/progress_model.dart';
import '../../../l10n/app_localizations_context.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);
    final cloudDataAsync = ref.watch(cloudDataProvider);
    final cloudReadsEnabled = ref.watch(dataModeProvider) == DataMode.cloud;
    final cloudData = cloudDataAsync.asData?.value;
    final cloudProgress = cloudData?.progress;
    final userId = user?.uid ?? 'guest';

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.progressJourneyTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // XP Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<int>(
                    future: progressRepo.getTotalXp(userId),
                    builder: (context, snapshot) => Text(
                      context.l10n.progressXpTotal(snapshot.data ?? 0),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.progressLearner(
                      user?.nickname ?? context.l10n.progressExplorer,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (cloudReadsEnabled && cloudDataAsync.isLoading)
              const _CloudProgressNotice(
                message:
                    'Loading cloud progress. Local progress remains available.',
              )
            else if (cloudReadsEnabled && cloudData?.message != null)
              _CloudProgressNotice(message: cloudData!.message!),
            if (cloudProgress != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cloud progress',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('XP: ${cloudProgress.xp}'),
                      Text(
                        'Stories completed: ${cloudProgress.storiesCompleted}',
                      ),
                      Text(
                        'Chapters completed: ${cloudProgress.chaptersCompleted}',
                      ),
                      Text(
                        'Vocabulary practiced: ${cloudProgress.vocabularyPracticed}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              context.l10n.progressStoriesInProgress,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<StoryProgressModel>>(
              future: progressRepo.getAllProgress(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final progressList = snapshot.data ?? [];
                if (progressList.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(context.l10n.progressStartPrompt),
                    ),
                  );
                }

                return Column(
                  children: progressList.map((p) {
                    final storyTitle = p.storyId == 'ibalong'
                        ? 'Ibalong'
                        : context.l10n.progressMayonStoryTitle;
                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.bookmark_added,
                          color: Color(0xFFD97706),
                        ),
                        title: Text(
                          storyTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          context.l10n.progressChapterCount(p.completedCount),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.progressRecentAttempts,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<RecentAttemptModel>>(
              future: progressRepo.getRecentAttempts(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final attempts = snapshot.data ?? [];
                if (attempts.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(context.l10n.progressNoQuizAttemptsRecorded),
                    ),
                  );
                }

                return Column(
                  children: attempts.map((att) {
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          att.passed ? Icons.check_circle : Icons.cancel,
                          color: att.passed
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                        title: Text(
                          att.chapterTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          context.l10n.progressScoreAndXp(
                            att.score,
                            att.xpAwarded,
                          ),
                        ),
                        trailing: Text(
                          att.passed
                              ? context.l10n.progressPassed
                              : context.l10n.progressRetry,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: att.passed
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudProgressNotice extends StatelessWidget {
  const _CloudProgressNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF9A3412))),
    );
  }
}
