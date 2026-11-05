// APP ROUTER

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/providers.dart';
import '../../core/models/chapter_journey_model.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/consent/presentation/consent_gate_screen.dart';
import '../../features/stories/presentation/home_screen.dart';
import '../../features/stories/presentation/cleared_stories_screen.dart';
import '../../features/stories/presentation/chapter_list_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/challenges/presentation/challenge_screen.dart';
import '../../features/challenges/presentation/chapter_cleared_screen.dart';
import '../../features/challenges/presentation/chapter_completion_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/vocabulary/presentation/vocabulary_practice_screen.dart';
import '../../features/stories/presentation/story_completion_screen.dart';
import '../../core/models/user_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/library',
    redirect: (context, state) {
      final authState = ref.read(authRoutingStateProvider);
      final isAuthPath =
          state.uri.path == '/login' || state.uri.path == '/register';

      if (authState == null || !authState.isAuthenticated) {
        return isAuthPath ? null : '/login';
      }

      // Safeguard: Check guardian approval
      if (authState.approvalStatus == ApprovalStatus.pending &&
          state.uri.path != '/consent-pending') {
        return '/consent-pending';
      }

      if (isAuthPath) {
        return '/library';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/consent-pending',
        builder: (context, state) => const ConsentGateScreen(),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/cleared-stories',
        builder: (context, state) => const ClearedStoriesScreen(),
      ),
      GoRoute(
        path: '/story/:storyId',
        builder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          return ChapterListScreen(storyId: storyId);
        },
      ),
      GoRoute(
        path: '/reader/:storyId/:chapterId',
        builder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          final chapterId = state.pathParameters['chapterId']!;
          return ReaderScreen(storyId: storyId, chapterId: chapterId);
        },
      ),
      GoRoute(
        path: '/challenge/:storyId/:chapterId',
        builder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          final chapterId = state.pathParameters['chapterId']!;
          return ChallengeScreen(storyId: storyId, chapterId: chapterId);
        },
      ),
      GoRoute(
        path: '/chapter-cleared',
        builder: (context, state) {
          final extra = state.extra;
          return ChapterClearedScreen(
            journey: extra is ChapterJourney ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/chapter-completion',
        builder: (context, state) {
          final extra = state.extra;
          return ChapterCompletionScreen(
            journey: extra is ChapterJourney ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/story-completion/:storyId',
        builder: (context, state) =>
            StoryCompletionScreen(storyId: state.pathParameters['storyId']!),
      ),
      GoRoute(
        path: '/vocabulary/:chapterId/:mode',
        builder: (context, state) {
          final extra = state.extra;
          return VocabularyPracticeScreen(
            chapterId: state.pathParameters['chapterId']!,
            journey: extra is ChapterJourney ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );

  ref.listen(authRoutingStateProvider, (previous, next) {
    if (previous != next) router.refresh();
  });
  ref.onDispose(router.dispose);

  return router;
});
