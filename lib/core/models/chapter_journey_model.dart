import 'attempt_result_model.dart';

class ChapterJourney {
  const ChapterJourney({
    required this.storyId,
    required this.chapterId,
    required this.quizResult,
    this.vocabularyCompleted = false,
    this.wordsPracticed = 0,
  });

  final String storyId;
  final String chapterId;
  final AttemptResultModel quizResult;
  final bool vocabularyCompleted;
  final int wordsPracticed;

  String get continueLocation => quizResult.passed
      ? quizResult.nextChapterId == null
            ? '/story-completion/$storyId'
            : '/story/$storyId'
      : '/story/$storyId';

  ChapterJourney copyWith({bool? vocabularyCompleted, int? wordsPracticed}) =>
      ChapterJourney(
        storyId: storyId,
        chapterId: chapterId,
        quizResult: quizResult,
        vocabularyCompleted: vocabularyCompleted ?? this.vocabularyCompleted,
        wordsPracticed: wordsPracticed ?? this.wordsPracticed,
      );
}
