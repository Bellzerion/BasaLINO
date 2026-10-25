import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/models/chapter_model.dart';
import '../../../core/models/story_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(storyRepositoryProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: FutureBuilder<List<StoryModel>>(
        future: repo.getStories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final stories = snapshot.data!;
          if (stories.isEmpty) return const Center(child: Text('Stories are unavailable right now.'));
          final story = stories.firstWhere((s) => s.id == 'mayon', orElse: () => stories.first);
          final name = user?.nickname.trim().isNotEmpty == true ? user!.nickname : 'Explorer';
          return FutureBuilder<List<ChapterModel>>(
            future: progressRepo.getChaptersWithStatus(
              storyId: story.id,
              userId: user?.uid ?? 'guest',
            ),
            builder: (context, chapterSnapshot) {
              if (!chapterSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final chapters = chapterSnapshot.data!;
              return SafeArea(
            child: Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _Welcome(name: name),
                    const SizedBox(height: 16),
                    _AdventureCard(story: story, chapters: chapters),
                    const SizedBox(height: 16),
                    const Text('Adventure Map', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    _Map(story: story, chapters: chapters),
                    const SizedBox(height: 14),
                    const Text('More stories to explore', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    ...stories.where((s) => s.id != story.id).map((s) => Card(
                      child: ListTile(
                        onTap: () => context.push('/story/${s.id}'),
                        leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF075C31)),
                        title: Text(s.titleEn, style: const TextStyle(fontWeight: FontWeight.w800)),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    )),
                  ]),
                ),
              ),
              _Nav(
                onClearedStories: () => context.push('/cleared-stories'),
                onProgress: () => context.push('/progress'),
                onProfile: () => context.push('/profile'),
              ),
            ]),
              );
            },
          );
        },
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
    decoration: const BoxDecoration(color: Color(0xFF075C31), borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SizedBox(
          width: 42,
          height: 32,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Color(0xFF075C31), BlendMode.multiply),
            child: Image.asset(AppAssets.mascot, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 4),
        const Text.rich(TextSpan(style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800), children: [
          TextSpan(text: 'Basa', style: TextStyle(color: Color(0xFF68A68E))),
          TextSpan(text: 'LINO', style: TextStyle(color: Color(0xFFFF8D28))),
        ])),
      ]),
      const SizedBox(height: 20),
      Text('Hi, $name!', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      const Text('Ready for your next Adventure?', style: TextStyle(color: Color(0xFFE2F0E9), fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _AdventureCard extends StatelessWidget {
  const _AdventureCard({required this.story, required this.chapters});
  final StoryModel story;
  final List<ChapterModel> chapters;
  @override
  Widget build(BuildContext context) {
    final current = chapters.firstWhere(
      (chapter) => chapter.isUnlocked,
      orElse: () => chapters.isNotEmpty ? chapters.last : const ChapterModel(id: '', storyId: '', orderIndex: 0, status: ChapterStatus.locked),
    );
    final completed = chapters.where((chapter) => chapter.isCompleted).length;
    final isNewJourney = completed == 0 && current.orderIndex == 0;
    final progress = chapters.isEmpty ? 0.0 : completed / chapters.length;
    return Container(
    padding: const EdgeInsets.fromLTRB(17, 13, 17, 10),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3C8068), Color(0xFF4CB18B)]), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .30), borderRadius: BorderRadius.circular(8)), child: const Text('Adventure - Filipino Story', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))),
      const SizedBox(height: 7),
      Text(story.titleEn, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      Text(isNewJourney ? 'Your first chapter is ready' : 'Chapter ${current.orderIndex + 1} of ${chapters.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: const Color(0xFFD7E3DB), valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8D28)))),
      Align(alignment: Alignment.center, child: FilledButton(onPressed: current.id.isEmpty ? null : () => context.push('/reader/${story.id}/${current.id}'), style: FilledButton.styleFrom(minimumSize: const Size(110, 30), backgroundColor: const Color(0xFFFF8D28), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16)), child: Text(isNewJourney ? 'Start Reading' : 'Continue', style: const TextStyle(fontWeight: FontWeight.w900)))),
    ]),
  );
  }
}

class _Map extends StatelessWidget {
  const _Map({required this.story, required this.chapters});
  final StoryModel story;
  final List<ChapterModel> chapters;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: (chapters.length * 68).toDouble(),
    child: Column(children: chapters.map((chapter) => _ChapterMapItem(story: story, chapter: chapter)).toList()),
  );
}

class _ChapterMapItem extends StatelessWidget {
  const _ChapterMapItem({required this.story, required this.chapter});
  final StoryModel story;
  final ChapterModel chapter;

  @override
  Widget build(BuildContext context) {
    final unlocked = chapter.isUnlocked || chapter.isCompleted;
    final color = chapter.isCompleted ? const Color(0xFF3E8970) : unlocked ? const Color(0xFFFF8D28) : const Color(0xFFB9B9B2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: unlocked ? const Color(0xEDFFFDF7) : const Color(0xC9E2E2DC),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: unlocked ? () => context.push('/reader/${story.id}/${chapter.id}') : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: .7)), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              CircleAvatar(backgroundColor: color, child: Icon(chapter.isCompleted ? Icons.check : unlocked ? Icons.play_arrow_rounded : Icons.lock_outline_rounded, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(child: Text('Chapter ${chapter.orderIndex + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: unlocked ? const Color(0xFF18231D) : const Color(0xFF777771)))),
              Text(chapter.isCompleted ? 'Completed' : unlocked ? 'Start' : 'Locked', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({
    required this.onClearedStories,
    required this.onProgress,
    required this.onProfile,
  });

  final VoidCallback onClearedStories;
  final VoidCallback onProgress;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => Container(
        height: 62,
        color: const Color(0xFFDCEDE7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(Icons.home_rounded, color: Color(0xFF075C31)),
            IconButton(
              tooltip: 'Cleared stories',
              onPressed: onClearedStories,
              icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF075C31)),
            ),
            IconButton(onPressed: onProgress, icon: const Icon(Icons.star_rounded, color: Color(0xFF075C31))),
            IconButton(onPressed: onProfile, icon: const Icon(Icons.person_rounded, color: Color(0xFF075C31))),
          ],
        ),
      );
}
