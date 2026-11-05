import 'package:basalino/core/services/auth_repository.dart';
import 'package:basalino/core/services/local_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('vocabulary bonus is persisted and awarded once per chapter', () async {
    final repository = LocalAuthRepository();

    expect(
      await repository.awardVocabularyBonus(chapterId: 'ibalong_ch1'),
      isTrue,
    );
    expect((await repository.getCurrentUser())?.totalXp, 50);
    expect(
      await repository.awardVocabularyBonus(chapterId: 'ibalong_ch1'),
      isFalse,
    );
    expect((await repository.getCurrentUser())?.totalXp, 50);

    final restored = LocalAuthRepository();
    expect((await restored.getCurrentUser())?.totalXp, 50);
    expect(
      await restored.awardVocabularyBonus(chapterId: 'ibalong_ch1'),
      isFalse,
    );
    expect(AuthRepository.vocabularyBonusXp, 5);
  });
}
