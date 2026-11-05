import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/story_model.dart';
import '../../../l10n/app_localizations_context.dart';

class ChapterListScreen extends ConsumerWidget {
  const ChapterListScreen({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyRepo = ref.watch(storyRepositoryProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid ?? 'guest';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: context.l10n.backLabel,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/library'),
        ),
        title: Text(context.l10n.chaptersTitle),
      ),
      body: FutureBuilder<List<StoryModel>>(
        future: storyRepo.getStories(),
        builder: (context, storySnap) {
          final story = storySnap.data?.firstWhere(
            (s) => s.id == storyId,
            orElse: () => StoryModel(
              id: storyId,
              titleEn: context.l10n.chapterFallbackStory,
              descriptionEn: '',
              availableLanguages: const ['en'],
              chapterCount: 0,
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFFFEF3C7)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story?.titleEn ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.chapterListDescription,
                      style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ChapterModel>>(
                  future: progressRepo.getChaptersWithStatus(
                    storyId: storyId,
                    userId: userId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          context.l10n.chapterError(snapshot.error.toString()),
                        ),
                      );
                    }

                    final chapters = snapshot.data ?? [];
                    if (chapters.isEmpty) {
                      return Center(child: Text(context.l10n.chapterEmpty));
                    }

                    final nextChapter = chapters
                        .where((chapter) => chapter.isUnlocked)
                        .fold<ChapterModel?>(
                          null,
                          (next, chapter) =>
                              next == null ||
                                  chapter.orderIndex < next.orderIndex
                              ? chapter
                              : next,
                        );
                    final storyComplete = nextChapter == null;

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: chapters.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final ch = chapters[index];
                              return _ChapterTile(
                                storyId: storyId,
                                chapter: ch,
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: nextChapter != null
                                  ? () => context.push(
                                      '/reader/$storyId/${nextChapter.id}',
                                    )
                                  : storyComplete
                                  ? () =>
                                        context.go('/story-completion/$storyId')
                                  : null,
                              icon: Icon(
                                storyComplete
                                    ? Icons.celebration_rounded
                                    : Icons.explore_rounded,
                              ),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  context.l10n.continueAdventure,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.storyId, required this.chapter});

  final String storyId;
  final ChapterModel chapter;

  @override
  Widget build(BuildContext context) {
    Color cardBorder;
    Color iconColor;
    IconData iconData;
    String statusLabel;

    switch (chapter.status) {
      case ChapterStatus.completed:
        cardBorder = const Color(0xFF10B981);
        iconColor = const Color(0xFF10B981);
        iconData = Icons.check_circle_rounded;
        statusLabel = context.l10n.chapterCompleted;
        break;
      case ChapterStatus.unlocked:
        cardBorder = const Color(0xFFD97706);
        iconColor = const Color(0xFFD97706);
        iconData = Icons.play_circle_fill_rounded;
        statusLabel = context.l10n.chapterStatusUnlocked;
        break;
      case ChapterStatus.locked:
        cardBorder = const Color(0xFFD1D5DB);
        iconColor = const Color(0xFF9CA3AF);
        iconData = Icons.lock_rounded;
        statusLabel = context.l10n.chapterLocked;
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorder, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(iconData, color: iconColor, size: 36),
        title: Text(
          context.l10n.chapterLabel(chapter.orderIndex + 1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: chapter.isLocked
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          statusLabel,
          style: TextStyle(
            color: iconColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: chapter.isLocked
            ? null
            : const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF6B7280),
              ),
        onTap: chapter.isLocked
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.chapterQuizUnlockHint),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            : () {
                context.push('/reader/$storyId/${chapter.id}');
              },
      ),
    );
  }
}
