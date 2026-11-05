// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BasaLINO';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get saveLabel => 'Save';

  @override
  String get retryLabel => 'Retry';

  @override
  String get closeLabel => 'Close';

  @override
  String get nextLabel => 'Next';

  @override
  String get backLabel => 'Back';

  @override
  String get submitLabel => 'Submit';

  @override
  String get loadingLabel => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNoInternet =>
      'No internet connection. Please check your network.';

  @override
  String get errorUnauthorized =>
      'You are not authorized to perform this action.';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignUp => 'Create Account';

  @override
  String get authSignOut => 'Sign Out';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authNickname => 'Nickname';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authResetPassword => 'Reset Password';

  @override
  String get authResetPasswordSent =>
      'Password reset email sent. Check your inbox.';

  @override
  String get authNoAccount => 'Don\'t have an account? Sign up';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authEmailInvalid => 'Enter a valid email address.';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters.';

  @override
  String get authNicknameTooShort => 'Nickname must be at least 2 characters.';

  @override
  String get authErrorEmailInUse => 'This email is already in use.';

  @override
  String get authErrorWrongPassword => 'Incorrect email or password.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please wait and try again.';

  @override
  String get consentTitle => 'Parental Approval Required';

  @override
  String get consentBody =>
      'BasaLINO is designed for learners under 18. A parent or guardian must approve your account before you can access stories and challenges. Your parent or guardian will receive an email with instructions.';

  @override
  String get consentPending =>
      'Your account is pending guardian approval. Please ask your parent or guardian to check their email.';

  @override
  String get consentContactSupport => 'Contact support';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileLanguagePreference => 'Reading Language';

  @override
  String get profileLanguageEn => 'English';

  @override
  String get profileLanguageTl => 'Tagalog';

  @override
  String get profileLanguageBik => 'Bikol';

  @override
  String get libraryTitle => 'Stories';

  @override
  String get libraryEmpty => 'No stories available yet.';

  @override
  String libraryChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '1 chapter',
    );
    return '$_temp0';
  }

  @override
  String get libraryAvailableIn => 'Available in:';

  @override
  String libraryProgressLabel(int completed, int total) {
    return '$completed of $total chapters';
  }

  @override
  String get chaptersTitle => 'Chapters';

  @override
  String get chapterLocked => 'Locked';

  @override
  String get chapterCompleted => 'Completed';

  @override
  String get chapterUnlocked => 'Start Reading';

  @override
  String get chapterCurrent => 'Continue';

  @override
  String get chapterLockedHint => 'Complete the previous chapter to unlock.';

  @override
  String get readerTextSizeLabel => 'Text Size';

  @override
  String get readerVocabHintTitle => 'Vocabulary';

  @override
  String get readerStartChallenge => 'Take the Quiz';

  @override
  String get readerAlreadyCompleted => 'Chapter Completed ✓';

  @override
  String readerChapterComplete(int xp) {
    return 'Chapter complete! You earned $xp XP.';
  }

  @override
  String get challengeTitle => 'Reading Check';

  @override
  String challengeQuestion(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get challengeSubmit => 'Submit Answers';

  @override
  String get challengeSubmitting => 'Checking your answers…';

  @override
  String challengeResultPass(int score) {
    return 'Well done! You scored $score%.';
  }

  @override
  String challengeResultFail(int score) {
    return 'You scored $score%. Try again to unlock the next chapter.';
  }

  @override
  String challengeXpEarned(int xp) {
    return '+$xp XP Earned!';
  }

  @override
  String get challengeAlreadyCompleted =>
      'You have already completed this quiz.';

  @override
  String get challengeErrorNotEligible =>
      'You are not eligible to attempt this quiz.';

  @override
  String get challengeNextChapter => 'Next Chapter';

  @override
  String get challengeRetry => 'Try Again';

  @override
  String get challengeBackToStory => 'Back to Story';

  @override
  String get progressTitle => 'My Progress';

  @override
  String progressXpTotal(int xp) {
    return '$xp XP earned';
  }

  @override
  String get progressStoriesStarted => 'Stories started';

  @override
  String get progressChaptersCompleted => 'Chapters completed';

  @override
  String get progressRecentAttempts => 'Recent Quiz Results';

  @override
  String get progressNoAttempts => 'No quiz results yet.';

  @override
  String progressAttemptScore(int score, String chapter) {
    return '$score% on $chapter';
  }

  @override
  String get loginTagline => 'Reading becomes an adventure.';

  @override
  String get loginIntroduction =>
      'Discover Philippine stories, one chapter at a time.';

  @override
  String get authEmailLabel => 'Email Address';

  @override
  String get authCompleteRequired => 'Please complete all required fields.';

  @override
  String get registerIntroduction =>
      'Join BasaLINO and start your reading quest.';

  @override
  String get authLearnerNicknameLabel => 'Learner Nickname';

  @override
  String get homeStoriesUnavailable => 'Stories are unavailable right now.';

  @override
  String get homeExplorer => 'Explorer';

  @override
  String get homeAdventureMap => 'Adventure Map';

  @override
  String get homeMoreStories => 'More stories to explore';

  @override
  String homeGreeting(String name) {
    return 'Hi, $name!';
  }

  @override
  String get homeGreetingPrompt => 'Ready for your next Adventure?';

  @override
  String get homeAdventureFilipino => 'Adventure - Filipino Story';

  @override
  String get homeFirstChapterReady => 'Your first chapter is ready';

  @override
  String homeChapterProgress(int current, int total) {
    return 'Chapter $current of $total';
  }

  @override
  String get homeClearedStories => 'Cleared stories';

  @override
  String get homeChapterStart => 'Start';

  @override
  String get homeStoryCompleted => 'Story Complete';

  @override
  String get progressJourneyTitle => 'My Learning Journey';

  @override
  String progressLearner(String name) {
    return 'Learner: $name';
  }

  @override
  String get progressStoriesInProgress => 'Stories in Progress';

  @override
  String get progressStartPrompt =>
      'Start reading stories to track your progress!';

  @override
  String progressChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters completed',
      one: '1 chapter completed',
    );
    return '$_temp0';
  }

  @override
  String get progressNoQuizAttemptsRecorded => 'No quiz attempts recorded yet.';

  @override
  String progressScoreAndXp(int score, int xp) {
    return 'Score: $score% • +$xp XP';
  }

  @override
  String get progressPassed => 'PASSED';

  @override
  String get progressRetry => 'RETRY';

  @override
  String get progressExplorer => 'Explorer';

  @override
  String get progressMayonStoryTitle => 'The Legend of Mount Mayon';

  @override
  String get profileLearner => 'Learner';

  @override
  String get profileEnglishDescription => 'Default content & quizzes';

  @override
  String get profileTagalogDescription => 'Wikang Pambansa';

  @override
  String get profileBikolCentral => 'Bikol (Central)';

  @override
  String get profileBikolDescription => 'Bikol Sentral Translation';

  @override
  String get challengeIncompleteQuestions =>
      'Please answer all questions before submitting.';

  @override
  String get challengeUnavailable => 'Challenge content currently unavailable.';

  @override
  String challengeInstructions(int count) {
    return 'Answer all $count questions correctly to earn XP and unlock the next chapter.';
  }

  @override
  String challengeSubmitFailed(String error) {
    return 'Failed to submit: $error';
  }

  @override
  String get challengeResultAwesome => 'Awesome Job!';

  @override
  String get challengeResultKeepPracticing => 'Keep Practicing!';

  @override
  String challengeResultPassDetail(int score, int correct, int total) {
    return 'You scored $score% ($correct/$total correct)!';
  }

  @override
  String challengeResultFailDetail(int score, int threshold) {
    return 'You scored $score%. Score at least $threshold% to unlock the next chapter.';
  }

  @override
  String get challengeBackToChapters => 'Back to Chapters';

  @override
  String get challengeReadNextChapter => 'Read Next Chapter';

  @override
  String get readerTitle => 'Story Reader';

  @override
  String get readerAdjustTextSize => 'Adjust text size';

  @override
  String get readerSelectLanguage => 'Select Language';

  @override
  String get readerLanguageEnglish => 'English (EN)';

  @override
  String get readerLanguageTagalog => 'Tagalog (TL)';

  @override
  String get readerLanguageBikol => 'Bikol (BIK)';

  @override
  String get readerUnavailable =>
      'Chapter content unavailable in selected language.';

  @override
  String get readerReadInEnglish => 'Read in English';

  @override
  String get readerTranslationReview =>
      'This translation is in review by language specialists.';

  @override
  String get readerFallbackVocabularyDefinition =>
      'A key story vocabulary term.';

  @override
  String get chapterListDescription =>
      'Read each chapter in order and pass the reading check to unlock the next chapter.';

  @override
  String chapterError(String error) {
    return 'Error: $error';
  }

  @override
  String get chapterEmpty => 'No chapters found.';

  @override
  String chapterLabel(int number) {
    return 'Chapter $number';
  }

  @override
  String get chapterStatusUnlocked => 'Unlocked';

  @override
  String get chapterQuizUnlockHint =>
      'Complete the previous chapter quiz to unlock this chapter.';

  @override
  String get chapterFallbackStory => 'Story';

  @override
  String get clearedStoriesTitle => 'Cleared Stories';

  @override
  String get clearedStoriesLoadError =>
      'Your cleared stories could not be loaded.';

  @override
  String clearedStoryChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters cleared',
      one: '1 chapter cleared',
    );
    return '$_temp0';
  }

  @override
  String get clearedStoriesEmptyTitle => 'No cleared stories yet';

  @override
  String get clearedStoriesEmptyDescription =>
      'Finish every chapter and its reading check to add a story to your collection.';

  @override
  String get clearedStoriesContinueReading => 'Continue reading';

  @override
  String get consentInformation =>
      'BasaLINO takes child safety and privacy seriously. An email was sent to your registered guardian with instructions to approve your learner access.';

  @override
  String get consentApprovalStillPending =>
      'Approval status checked: still pending.';

  @override
  String get consentCheckApproval => 'Check Approval Status';

  @override
  String get libraryAppBarTitle => 'BasaLINO Library';

  @override
  String get libraryProgressTooltip => 'My Progress';

  @override
  String get libraryProfileTooltip => 'Profile & Language';

  @override
  String libraryLoadError(String error) {
    return 'Error loading stories: $error';
  }

  @override
  String get readerCheckKnowledge => 'Check Knowledge';

  @override
  String get knowledgeStoryQuiz => 'Story Quiz';

  @override
  String get knowledgeVocabularyChallenge => 'Vocabulary Challenge';

  @override
  String get knowledgeStoryQuizDescription =>
      'Test what happened in the chapter.';

  @override
  String get knowledgeVocabularyChallengeDescription =>
      'Practice important story words.';

  @override
  String get quizComplete => 'Quiz Complete!';

  @override
  String quizScore(int correct, int total) {
    return 'Score: $correct/$total';
  }

  @override
  String get startVocabularyChallenge => 'Start Vocabulary Challenge';

  @override
  String get vocabularyChapterPractice =>
      'Practice the key words from this chapter.';

  @override
  String get vocabularySkipForNow => 'Skip for now';

  @override
  String get continueAdventure => 'Continue Adventure';

  @override
  String get chapterComplete => 'Chapter Complete!';

  @override
  String get chapterCleared => 'Chapter Cleared!';

  @override
  String get bonusVocabularyChallenge => 'Bonus Vocabulary Challenge';

  @override
  String get vocabularyBonusDescription =>
      'Practice important words from this chapter and earn bonus XP.';

  @override
  String get greatJob => 'Great job!';

  @override
  String get youUnderstoodTheStory => 'You understood the story!';

  @override
  String get readyForNextAdventure => 'You are ready for the next adventure!';

  @override
  String bonusXpEarned(int xp) {
    return 'Bonus XP Earned: +$xp';
  }

  @override
  String get vocabularyBonusFailed =>
      'We couldn\'t save your bonus XP. Please try again.';

  @override
  String get vocabularyRetryBonus => 'Retry bonus';

  @override
  String get chapterPracticeComplete => 'Practice Complete';

  @override
  String get storyQuizComplete => 'Story Quiz Complete';

  @override
  String get vocabularyChallengeComplete => 'Vocabulary Challenge Complete';

  @override
  String get vocabularySkipped => 'Vocabulary Challenge Skipped';

  @override
  String get xpEarned => 'XP Earned';

  @override
  String get wordsPracticedLabel => 'Words Practiced';

  @override
  String wordsPracticed(int count) {
    return 'Words Practiced: $count';
  }

  @override
  String get chapterProgress => 'Chapter Progress';

  @override
  String chapterProgressCount(int completed, int total) {
    return '$completed of $total chapters complete';
  }

  @override
  String get chapterProgressUnavailable => 'Unavailable';

  @override
  String get chapterJourneyUnavailable =>
      'This chapter journey is no longer available.';

  @override
  String get storyCompletionTitle => 'Story Complete!';

  @override
  String get storyCompletionMessage =>
      'You completed the journey. You are ready for your next adventure!';

  @override
  String get storyCompletionReturnToMap => 'Return to Adventure Map';

  @override
  String get storyCompletionReplay => 'Replay Story';

  @override
  String get storyCompletionChapters => 'Chapters Completed';

  @override
  String get storyCompletionWordsPracticed => 'Vocabulary Words Practiced';

  @override
  String get storyCompletionXpEarned => 'Total XP Earned';

  @override
  String get storyCompletionDate => 'Completion Date';

  @override
  String get chapterListReturn => 'Return to chapters';

  @override
  String get vocabularyChallengePrompt =>
      'Choose the meaning that best matches the word.';

  @override
  String vocabularyWhatDoesWordMean(String word) {
    return 'What does \"$word\" mean?';
  }

  @override
  String get vocabularySubmitAnswer => 'Submit answer';

  @override
  String get vocabularyCorrectFeedback => 'Correct!';

  @override
  String get vocabularyIncorrectFeedback => 'Not quite.';

  @override
  String get vocabularyContinue => 'Continue';

  @override
  String get vocabularyComplete => 'Vocabulary challenge complete!';

  @override
  String get vocabularyBackToChapter => 'Back to chapter';

  @override
  String get vocabularyUnavailable => 'Vocabulary is not available yet.';

  @override
  String libraryCompletedChapterCount(int completed, int total) {
    return '$completed of $total chapters completed';
  }
}
