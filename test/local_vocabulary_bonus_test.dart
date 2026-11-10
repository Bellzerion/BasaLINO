import 'package:basalino/core/services/local_progress_repository.dart';
import 'package:basalino/core/services/local_story_repository.dart';
import 'package:basalino/core/services/progress_mutation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('vocabulary bonus is persisted and awarded once per chapter', () async {
    final stories = LocalStoryRepository();
    final repository = LocalProgressRepository(stories);
    final mutations = ProgressMutationService(
      progressRepository: repository,
      storyRepository: stories,
    );

    expect(
      await mutations.awardVocabularyBonus(
        userId: 'learner-1',
        chapterId: 'ibalong_ch1',
      ),
      isTrue,
    );
    expect(await repository.getTotalXp('learner-1'), 5);
    expect(
      await mutations.awardVocabularyBonus(
        userId: 'learner-1',
        chapterId: 'ibalong_ch1',
      ),
      isFalse,
    );
    expect(await repository.getTotalXp('learner-1'), 5);

    final restored = LocalProgressRepository(stories);
    expect(await restored.getTotalXp('learner-1'), 5);
    expect(
      await restored.awardVocabularyBonus(
        userId: 'learner-1',
        chapterId: 'ibalong_ch1',
        xpAwarded: ProgressMutationService.vocabularyBonusXp,
      ),
      isFalse,
    );
    expect(ProgressMutationService.vocabularyBonusXp, 5);
  });
}
