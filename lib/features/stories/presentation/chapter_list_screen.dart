import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/story_model.dart';

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
        title: const Text('Chapters'),
      ),
      body: FutureBuilder<List<StoryModel>>(
        future: storyRepo.getStories(),
        builder: (context, storySnap) {
          final story = storySnap.data?.firstWhere(
            (s) => s.id == storyId,
            orElse: () => StoryModel(
              id: storyId,
              titleEn: 'Story',
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
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                ),
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
                    const Text(
                      'Read each chapter in order and pass the reading check to unlock the next chapter.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ChapterModel>>(
                  future: progressRepo.getChaptersWithStatus(storyId: storyId, userId: userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final chapters = snapshot.data ?? [];
                    if (chapters.isEmpty) {
                      return const Center(child: Text('No chapters found.'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: chapters.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ch = chapters[index];
                        return _ChapterTile(storyId: storyId, chapter: ch);
                      },
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
        statusLabel = 'Completed';
        break;
      case ChapterStatus.unlocked:
        cardBorder = const Color(0xFFD97706);
        iconColor = const Color(0xFFD97706);
        iconData = Icons.play_circle_fill_rounded;
        statusLabel = 'Unlocked';
        break;
      case ChapterStatus.locked:
        cardBorder = const Color(0xFFD1D5DB);
        iconColor = const Color(0xFF9CA3AF);
        iconData = Icons.lock_rounded;
        statusLabel = 'Locked';
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
          'Chapter ${chapter.orderIndex + 1}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: chapter.isLocked ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
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
            : const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF6B7280)),
        onTap: chapter.isLocked
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete the previous chapter quiz to unlock this chapter.'),
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
