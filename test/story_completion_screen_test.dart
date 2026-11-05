import 'package:basalino/app/bootstrap/providers.dart';
import 'package:basalino/core/models/chapter_model.dart';
import 'package:basalino/core/models/chapter_translation_model.dart';
import 'package:basalino/core/models/story_model.dart';
import 'package:basalino/core/models/user_model.dart';
import 'package:basalino/core/services/local_auth_repository.dart';
import 'package:basalino/core/services/local_progress_repository.dart';
import 'package:basalino/core/services/story_repository.dart';
import 'package:basalino/features/stories/presentation/home_screen.dart';
import 'package:basalino/features/stories/presentation/story_completion_screen.dart';
import 'package:basalino/l10n/generated/app_localizations.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('completed final chapter shows journey summary and actions', (
    tester,
  ) async {
    final stories = _TestStoryRepository();
    final progress = LocalProgressRepository(stories);
    final auth = LocalAuthRepository();
    await _completeStory(progress, auth);
    final router = _testRouter();

    await tester.pumpWidget(
      _app(router: router, stories: stories, progress: progress, auth: auth),
    );
    await _pumpUntilVisible(tester, find.text('STORY COMPLETE!'));

    expect(find.text('STORY COMPLETE!'), findsOneWidget);
    expect(find.text('The Test Adventure'), findsOneWidget);
    expect(find.text('2 of 2 chapters complete'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('55'), findsOneWidget);
    expect(find.byType(ConfettiWidget), findsOneWidget);

    await tester.ensureVisible(find.text('Replay Story'));
    await tester.pump();
    await tester.tap(find.text('Replay Story'));
    await _pumpUntilVisible(tester, find.text('Story details'));
    expect(find.text('Story details'), findsOneWidget);
    final chapters = await progress.getChaptersWithStatus(
      storyId: 'test-story',
      userId: 'demo_learner_1',
    );
    expect(chapters.every((chapter) => chapter.isCompleted), isTrue);
  });

  testWidgets('incomplete story cannot open completion celebration', (
    tester,
  ) async {
    final stories = _TestStoryRepository();
    final progress = LocalProgressRepository(stories);
    await progress.recordAttemptAndUnlock(
      userId: 'demo_learner_1',
      storyId: 'test-story',
      chapterId: 'test-story_ch1',
      chapterTitle: 'Chapter 1',
      score: 100,
      xpAwarded: 35,
      passed: true,
      nextChapterId: 'test-story_ch2',
    );
    final router = _testRouter();

    await tester.pumpWidget(
      _app(
        router: router,
        stories: stories,
        progress: progress,
        auth: LocalAuthRepository(),
      ),
    );
    await _pumpUntilVisible(tester, find.text('Story details'));

    expect(find.text('Story details'), findsOneWidget);
    expect(find.text('STORY COMPLETE!'), findsNothing);
    expect(find.byType(ConfettiWidget), findsNothing);
  });

  testWidgets('home marks a fully completed story and offers replay', (
    tester,
  ) async {
    final stories = _TestStoryRepository();
    final progress = LocalProgressRepository(stories);
    final auth = LocalAuthRepository();
    await _completeStory(progress, auth);

    await tester.pumpWidget(
      _app(
        router: _testRouter(initialLocation: '/library', showHome: true),
        stories: stories,
        progress: progress,
        auth: auth,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Story Complete'), findsOneWidget);
    expect(find.text('Replay Story'), findsOneWidget);
  });
}

Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 50; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget did not appear: $finder');
}

Future<void> _completeStory(
  LocalProgressRepository progress,
  LocalAuthRepository auth,
) async {
  await progress.recordAttemptAndUnlock(
    userId: 'demo_learner_1',
    storyId: 'test-story',
    chapterId: 'test-story_ch1',
    chapterTitle: 'Chapter 1',
    score: 100,
    xpAwarded: 20,
    passed: true,
    nextChapterId: 'test-story_ch2',
  );
  await progress.recordAttemptAndUnlock(
    userId: 'demo_learner_1',
    storyId: 'test-story',
    chapterId: 'test-story_ch2',
    chapterTitle: 'Chapter 2',
    score: 80,
    xpAwarded: 30,
    passed: true,
  );
  await progress.recordVocabularyActivity(
    userId: 'demo_learner_1',
    chapterId: 'test-story_ch1',
    languageCode: 'en',
    word: 'journey',
    activityType: 'recall_challenge',
    correct: true,
  );
  await progress.recordVocabularyActivity(
    userId: 'demo_learner_1',
    chapterId: 'test-story_ch2',
    languageCode: 'en',
    word: 'journey',
    activityType: 'recall_challenge',
    correct: true,
  );
  await progress.recordVocabularyActivity(
    userId: 'demo_learner_1',
    chapterId: 'test-story_ch2',
    languageCode: 'en',
    word: 'brave',
    activityType: 'recall_challenge',
    correct: true,
  );
  await auth.awardVocabularyBonus(chapterId: 'test-story_ch1');
}

Widget _app({
  required GoRouter router,
  required _TestStoryRepository stories,
  required LocalProgressRepository progress,
  required LocalAuthRepository auth,
}) {
  return ProviderScope(
    overrides: [
      storyRepositoryProvider.overrideWithValue(stories),
      progressRepositoryProvider.overrideWithValue(progress),
      authRepositoryProvider.overrideWithValue(auth),
      currentUserProvider.overrideWith((ref) => _testUser),
      appLanguageProvider.overrideWith((ref) => 'en'),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

GoRouter _testRouter({
  String initialLocation = '/story-completion/test-story',
  bool showHome = false,
}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/story-completion/:storyId',
      builder: (context, state) =>
          StoryCompletionScreen(storyId: state.pathParameters['storyId']!),
    ),
    GoRoute(
      path: '/story/:storyId',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Story details'))),
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => showHome
          ? const HomeScreen()
          : const Scaffold(body: Center(child: Text('Map'))),
    ),
  ],
);

final _testUser = UserModel(
  uid: 'demo_learner_1',
  email: 'learner@example.com',
  nickname: 'Learner',
  preferredLanguage: 'en',
  approvalStatus: ApprovalStatus.approved,
  totalXp: 0,
  createdAt: DateTime(2026),
);

class _TestStoryRepository implements StoryRepository {
  @override
  Future<List<StoryModel>> getStories() async => const [
    StoryModel(
      id: 'test-story',
      titleEn: 'The Test Adventure',
      descriptionEn: 'A story for testing completion.',
      availableLanguages: ['en'],
      chapterCount: 2,
    ),
  ];

  @override
  Future<List<ChapterModel>> getChapters(String storyId) async => const [
    ChapterModel(
      id: 'test-story_ch1',
      storyId: 'test-story',
      orderIndex: 0,
      status: ChapterStatus.locked,
    ),
    ChapterModel(
      id: 'test-story_ch2',
      storyId: 'test-story',
      orderIndex: 1,
      status: ChapterStatus.locked,
    ),
  ];

  @override
  Future<ChapterTranslationModel?> getChapterTranslation({
    required String chapterId,
    required String languageCode,
  }) async => null;
}
