import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../core/models/progress_model.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final progressRepo = ref.watch(progressRepositoryProvider);
    final userId = user?.uid ?? 'guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning Journey'),
      ),
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
                  const Icon(Icons.stars_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    '${user?.totalXp ?? 0} XP',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Learner: ${user?.nickname ?? 'Explorer'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Stories in Progress',
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
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Start reading stories to track your progress!'),
                    ),
                  );
                }

                return Column(
                  children: progressList.map((p) {
                    final storyTitle = p.storyId == 'ibalong' ? 'Ibalong' : 'The Legend of Mount Mayon';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.bookmark_added, color: Color(0xFFD97706)),
                        title: Text(storyTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.completedCount} chapters completed'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Quiz Attempts',
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
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No quiz attempts recorded yet.'),
                    ),
                  );
                }

                return Column(
                  children: attempts.map((att) {
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          att.passed ? Icons.check_circle : Icons.cancel,
                          color: att.passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                        title: Text(att.chapterTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Score: ${att.score}% • +${att.xpAwarded} XP'),
                        trailing: Text(
                          att.passed ? 'PASSED' : 'RETRY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: att.passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
