import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/providers.dart';
import '../../../core/models/progress_model.dart';
import '../../../core/models/story_model.dart';

/// Shows stories whose every chapter has been completed by the learner.
class ClearedStoriesScreen extends ConsumerWidget {
  const ClearedStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyRepo = ref.watch(storyRepositoryProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid ?? 'guest';

    return Scaffold(
      appBar: AppBar(title: const Text('Cleared Stories')),
      body: FutureBuilder<({List<StoryModel> stories, List<StoryProgressModel> progress})>(
        future: Future.wait([
          storyRepo.getStories(),
          progressRepo.getAllProgress(userId),
        ]).then((results) => (
              stories: results[0] as List<StoryModel>,
              progress: results[1] as List<StoryProgressModel>,
            )),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Your cleared stories could not be loaded.'));
          }

          final progressByStory = {
            for (final progress in snapshot.data!.progress) progress.storyId: progress,
          };
          final clearedStories = snapshot.data!.stories.where((story) {
            final progress = progressByStory[story.id];
            return story.chapterCount > 0 && progress != null && progress.completedCount >= story.chapterCount;
          }).toList();

          if (clearedStories.isEmpty) {
            return const _EmptyClearedStories();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: clearedStories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final story = clearedStories[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF3E8970),
                    child: Icon(Icons.check_rounded, color: Colors.white),
                  ),
                  title: Text(story.titleEn, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text('${story.chapterCount} chapters cleared'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/story/${story.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyClearedStories extends StatelessWidget {
  const _EmptyClearedStories();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: Color(0xFFD8EAE1), shape: BoxShape.circle),
              child: const Icon(Icons.auto_stories_rounded, size: 44, color: Color(0xFF075C31)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No cleared stories yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Finish every chapter and its reading check to add a story to your collection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/library'),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Continue reading'),
            ),
          ],
        ),
      ),
    );
  }
}
