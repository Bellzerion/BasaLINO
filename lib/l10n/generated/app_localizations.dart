import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bik.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bik'),
    Locale('en'),
    Locale('tl'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'BasaLINO'**
  String get appName;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @submitLabel.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitLabel;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingLabel;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errorNoInternet;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to perform this action.'**
  String get errorUnauthorized;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authSignUp;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get authSignOut;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get authNickname;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPassword;

  /// No description provided for @authResetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get authResetPasswordSent;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authPasswordTooShort;

  /// No description provided for @authNicknameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be at least 2 characters.'**
  String get authNicknameTooShort;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get authErrorTooManyRequests;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Parental Approval Required'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'BasaLINO is designed for learners under 18. A parent or guardian must approve your account before you can access stories and challenges. Your parent or guardian will receive an email with instructions.'**
  String get consentBody;

  /// No description provided for @consentPending.
  ///
  /// In en, this message translates to:
  /// **'Your account is pending guardian approval. Please ask your parent or guardian to check their email.'**
  String get consentPending;

  /// No description provided for @consentContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get consentContactSupport;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @profileLanguagePreference.
  ///
  /// In en, this message translates to:
  /// **'Reading Language'**
  String get profileLanguagePreference;

  /// No description provided for @profileLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profileLanguageEn;

  /// No description provided for @profileLanguageTl.
  ///
  /// In en, this message translates to:
  /// **'Tagalog'**
  String get profileLanguageTl;

  /// No description provided for @profileLanguageBik.
  ///
  /// In en, this message translates to:
  /// **'Bikol'**
  String get profileLanguageBik;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get libraryTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stories available yet.'**
  String get libraryEmpty;

  /// No description provided for @libraryChapterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter} other{{count} chapters}}'**
  String libraryChapterCount(int count);

  /// No description provided for @libraryAvailableIn.
  ///
  /// In en, this message translates to:
  /// **'Available in:'**
  String get libraryAvailableIn;

  /// No description provided for @libraryProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} chapters'**
  String libraryProgressLabel(int completed, int total);

  /// No description provided for @chaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chaptersTitle;

  /// No description provided for @chapterLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get chapterLocked;

  /// No description provided for @chapterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get chapterCompleted;

  /// No description provided for @chapterUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get chapterUnlocked;

  /// No description provided for @chapterCurrent.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get chapterCurrent;

  /// No description provided for @chapterLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous chapter to unlock.'**
  String get chapterLockedHint;

  /// No description provided for @readerTextSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get readerTextSizeLabel;

  /// No description provided for @readerVocabHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get readerVocabHintTitle;

  /// No description provided for @readerStartChallenge.
  ///
  /// In en, this message translates to:
  /// **'Take the Quiz'**
  String get readerStartChallenge;

  /// No description provided for @readerAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Chapter Completed ✓'**
  String get readerAlreadyCompleted;

  /// No description provided for @readerChapterComplete.
  ///
  /// In en, this message translates to:
  /// **'Chapter complete! You earned {xp} XP.'**
  String readerChapterComplete(int xp);

  /// No description provided for @challengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Check'**
  String get challengeTitle;

  /// No description provided for @challengeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String challengeQuestion(int current, int total);

  /// No description provided for @challengeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Answers'**
  String get challengeSubmit;

  /// No description provided for @challengeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Checking your answers…'**
  String get challengeSubmitting;

  /// No description provided for @challengeResultPass.
  ///
  /// In en, this message translates to:
  /// **'Well done! You scored {score}%.'**
  String challengeResultPass(int score);

  /// No description provided for @challengeResultFail.
  ///
  /// In en, this message translates to:
  /// **'You scored {score}%. Try again to unlock the next chapter.'**
  String challengeResultFail(int score);

  /// No description provided for @challengeXpEarned.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP Earned!'**
  String challengeXpEarned(int xp);

  /// No description provided for @challengeAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'You have already completed this quiz.'**
  String get challengeAlreadyCompleted;

  /// No description provided for @challengeErrorNotEligible.
  ///
  /// In en, this message translates to:
  /// **'You are not eligible to attempt this quiz.'**
  String get challengeErrorNotEligible;

  /// No description provided for @challengeNextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next Chapter'**
  String get challengeNextChapter;

  /// No description provided for @challengeRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get challengeRetry;

  /// No description provided for @challengeBackToStory.
  ///
  /// In en, this message translates to:
  /// **'Back to Story'**
  String get challengeBackToStory;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get progressTitle;

  /// No description provided for @progressXpTotal.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP earned'**
  String progressXpTotal(int xp);

  /// No description provided for @progressStoriesStarted.
  ///
  /// In en, this message translates to:
  /// **'Stories started'**
  String get progressStoriesStarted;

  /// No description provided for @progressChaptersCompleted.
  ///
  /// In en, this message translates to:
  /// **'Chapters completed'**
  String get progressChaptersCompleted;

  /// No description provided for @progressRecentAttempts.
  ///
  /// In en, this message translates to:
  /// **'Recent Quiz Results'**
  String get progressRecentAttempts;

  /// No description provided for @progressNoAttempts.
  ///
  /// In en, this message translates to:
  /// **'No quiz results yet.'**
  String get progressNoAttempts;

  /// No description provided for @progressAttemptScore.
  ///
  /// In en, this message translates to:
  /// **'{score}% on {chapter}'**
  String progressAttemptScore(int score, String chapter);

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Reading becomes an adventure.'**
  String get loginTagline;

  /// No description provided for @loginIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Discover Philippine stories, one chapter at a time.'**
  String get loginIntroduction;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmailLabel;

  /// No description provided for @authCompleteRequired.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields.'**
  String get authCompleteRequired;

  /// No description provided for @registerIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Join BasaLINO and start your reading quest.'**
  String get registerIntroduction;

  /// No description provided for @authLearnerNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Learner Nickname'**
  String get authLearnerNicknameLabel;

  /// No description provided for @homeStoriesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stories are unavailable right now.'**
  String get homeStoriesUnavailable;

  /// No description provided for @homeExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get homeExplorer;

  /// No description provided for @homeAdventureMap.
  ///
  /// In en, this message translates to:
  /// **'Adventure Map'**
  String get homeAdventureMap;

  /// No description provided for @homeMoreStories.
  ///
  /// In en, this message translates to:
  /// **'More stories to explore'**
  String get homeMoreStories;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}!'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ready for your next Adventure?'**
  String get homeGreetingPrompt;

  /// No description provided for @homeAdventureFilipino.
  ///
  /// In en, this message translates to:
  /// **'Adventure - Filipino Story'**
  String get homeAdventureFilipino;

  /// No description provided for @homeFirstChapterReady.
  ///
  /// In en, this message translates to:
  /// **'Your first chapter is ready'**
  String get homeFirstChapterReady;

  /// No description provided for @homeChapterProgress.
  ///
  /// In en, this message translates to:
  /// **'Chapter {current} of {total}'**
  String homeChapterProgress(int current, int total);

  /// No description provided for @homeClearedStories.
  ///
  /// In en, this message translates to:
  /// **'Cleared stories'**
  String get homeClearedStories;

  /// No description provided for @homeChapterStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get homeChapterStart;

  /// No description provided for @homeStoryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Story Complete'**
  String get homeStoryCompleted;

  /// No description provided for @progressJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Learning Journey'**
  String get progressJourneyTitle;

  /// No description provided for @progressLearner.
  ///
  /// In en, this message translates to:
  /// **'Learner: {name}'**
  String progressLearner(String name);

  /// No description provided for @progressStoriesInProgress.
  ///
  /// In en, this message translates to:
  /// **'Stories in Progress'**
  String get progressStoriesInProgress;

  /// No description provided for @progressStartPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start reading stories to track your progress!'**
  String get progressStartPrompt;

  /// No description provided for @progressChapterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter completed} other{{count} chapters completed}}'**
  String progressChapterCount(int count);

  /// No description provided for @progressNoQuizAttemptsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No quiz attempts recorded yet.'**
  String get progressNoQuizAttemptsRecorded;

  /// No description provided for @progressScoreAndXp.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}% • +{xp} XP'**
  String progressScoreAndXp(int score, int xp);

  /// No description provided for @progressPassed.
  ///
  /// In en, this message translates to:
  /// **'PASSED'**
  String get progressPassed;

  /// No description provided for @progressRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get progressRetry;

  /// No description provided for @progressExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get progressExplorer;

  /// No description provided for @progressMayonStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'The Legend of Mount Mayon'**
  String get progressMayonStoryTitle;

  /// No description provided for @profileLearner.
  ///
  /// In en, this message translates to:
  /// **'Learner'**
  String get profileLearner;

  /// No description provided for @profileEnglishDescription.
  ///
  /// In en, this message translates to:
  /// **'Default content & quizzes'**
  String get profileEnglishDescription;

  /// No description provided for @profileTagalogDescription.
  ///
  /// In en, this message translates to:
  /// **'Wikang Pambansa'**
  String get profileTagalogDescription;

  /// No description provided for @profileBikolCentral.
  ///
  /// In en, this message translates to:
  /// **'Bikol (Central)'**
  String get profileBikolCentral;

  /// No description provided for @profileBikolDescription.
  ///
  /// In en, this message translates to:
  /// **'Bikol Sentral Translation'**
  String get profileBikolDescription;

  /// No description provided for @challengeIncompleteQuestions.
  ///
  /// In en, this message translates to:
  /// **'Please answer all questions before submitting.'**
  String get challengeIncompleteQuestions;

  /// No description provided for @challengeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Challenge content currently unavailable.'**
  String get challengeUnavailable;

  /// No description provided for @challengeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Answer all {count} questions correctly to earn XP and unlock the next chapter.'**
  String challengeInstructions(int count);

  /// No description provided for @challengeSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit: {error}'**
  String challengeSubmitFailed(String error);

  /// No description provided for @challengeResultAwesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome Job!'**
  String get challengeResultAwesome;

  /// No description provided for @challengeResultKeepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep Practicing!'**
  String get challengeResultKeepPracticing;

  /// No description provided for @challengeResultPassDetail.
  ///
  /// In en, this message translates to:
  /// **'You scored {score}% ({correct}/{total} correct)!'**
  String challengeResultPassDetail(int score, int correct, int total);

  /// No description provided for @challengeResultFailDetail.
  ///
  /// In en, this message translates to:
  /// **'You scored {score}%. Score at least {threshold}% to unlock the next chapter.'**
  String challengeResultFailDetail(int score, int threshold);

  /// No description provided for @challengeBackToChapters.
  ///
  /// In en, this message translates to:
  /// **'Back to Chapters'**
  String get challengeBackToChapters;

  /// No description provided for @challengeReadNextChapter.
  ///
  /// In en, this message translates to:
  /// **'Read Next Chapter'**
  String get challengeReadNextChapter;

  /// No description provided for @readerTitle.
  ///
  /// In en, this message translates to:
  /// **'Story Reader'**
  String get readerTitle;

  /// No description provided for @readerAdjustTextSize.
  ///
  /// In en, this message translates to:
  /// **'Adjust text size'**
  String get readerAdjustTextSize;

  /// No description provided for @readerSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get readerSelectLanguage;

  /// No description provided for @readerLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English (EN)'**
  String get readerLanguageEnglish;

  /// No description provided for @readerLanguageTagalog.
  ///
  /// In en, this message translates to:
  /// **'Tagalog (TL)'**
  String get readerLanguageTagalog;

  /// No description provided for @readerLanguageBikol.
  ///
  /// In en, this message translates to:
  /// **'Bikol (BIK)'**
  String get readerLanguageBikol;

  /// No description provided for @readerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Chapter content unavailable in selected language.'**
  String get readerUnavailable;

  /// No description provided for @readerReadInEnglish.
  ///
  /// In en, this message translates to:
  /// **'Read in English'**
  String get readerReadInEnglish;

  /// No description provided for @readerTranslationReview.
  ///
  /// In en, this message translates to:
  /// **'This translation is in review by language specialists.'**
  String get readerTranslationReview;

  /// No description provided for @readerFallbackVocabularyDefinition.
  ///
  /// In en, this message translates to:
  /// **'A key story vocabulary term.'**
  String get readerFallbackVocabularyDefinition;

  /// No description provided for @chapterListDescription.
  ///
  /// In en, this message translates to:
  /// **'Read each chapter in order and pass the reading check to unlock the next chapter.'**
  String get chapterListDescription;

  /// No description provided for @chapterError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String chapterError(String error);

  /// No description provided for @chapterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chapters found.'**
  String get chapterEmpty;

  /// No description provided for @chapterLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterLabel(int number);

  /// No description provided for @chapterStatusUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get chapterStatusUnlocked;

  /// No description provided for @chapterQuizUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous chapter quiz to unlock this chapter.'**
  String get chapterQuizUnlockHint;

  /// No description provided for @chapterFallbackStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get chapterFallbackStory;

  /// No description provided for @clearedStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cleared Stories'**
  String get clearedStoriesTitle;

  /// No description provided for @clearedStoriesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Your cleared stories could not be loaded.'**
  String get clearedStoriesLoadError;

  /// No description provided for @clearedStoryChapterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter cleared} other{{count} chapters cleared}}'**
  String clearedStoryChapterCount(int count);

  /// No description provided for @clearedStoriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No cleared stories yet'**
  String get clearedStoriesEmptyTitle;

  /// No description provided for @clearedStoriesEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Finish every chapter and its reading check to add a story to your collection.'**
  String get clearedStoriesEmptyDescription;

  /// No description provided for @clearedStoriesContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get clearedStoriesContinueReading;

  /// No description provided for @consentInformation.
  ///
  /// In en, this message translates to:
  /// **'BasaLINO takes child safety and privacy seriously. An email was sent to your registered guardian with instructions to approve your learner access.'**
  String get consentInformation;

  /// No description provided for @consentApprovalStillPending.
  ///
  /// In en, this message translates to:
  /// **'Approval status checked: still pending.'**
  String get consentApprovalStillPending;

  /// No description provided for @consentCheckApproval.
  ///
  /// In en, this message translates to:
  /// **'Check Approval Status'**
  String get consentCheckApproval;

  /// No description provided for @libraryAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'BasaLINO Library'**
  String get libraryAppBarTitle;

  /// No description provided for @libraryProgressTooltip.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get libraryProgressTooltip;

  /// No description provided for @libraryProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile & Language'**
  String get libraryProfileTooltip;

  /// No description provided for @libraryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading stories: {error}'**
  String libraryLoadError(String error);

  /// No description provided for @readerCheckKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Check Knowledge'**
  String get readerCheckKnowledge;

  /// No description provided for @knowledgeStoryQuiz.
  ///
  /// In en, this message translates to:
  /// **'Story Quiz'**
  String get knowledgeStoryQuiz;

  /// No description provided for @knowledgeVocabularyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Challenge'**
  String get knowledgeVocabularyChallenge;

  /// No description provided for @knowledgeStoryQuizDescription.
  ///
  /// In en, this message translates to:
  /// **'Test what happened in the chapter.'**
  String get knowledgeStoryQuizDescription;

  /// No description provided for @knowledgeVocabularyChallengeDescription.
  ///
  /// In en, this message translates to:
  /// **'Practice important story words.'**
  String get knowledgeVocabularyChallengeDescription;

  /// No description provided for @quizComplete.
  ///
  /// In en, this message translates to:
  /// **'Quiz Complete!'**
  String get quizComplete;

  /// No description provided for @quizScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {correct}/{total}'**
  String quizScore(int correct, int total);

  /// No description provided for @startVocabularyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Start Vocabulary Challenge'**
  String get startVocabularyChallenge;

  /// No description provided for @vocabularyChapterPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice the key words from this chapter.'**
  String get vocabularyChapterPractice;

  /// No description provided for @vocabularySkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get vocabularySkipForNow;

  /// No description provided for @continueAdventure.
  ///
  /// In en, this message translates to:
  /// **'Continue Adventure'**
  String get continueAdventure;

  /// No description provided for @chapterComplete.
  ///
  /// In en, this message translates to:
  /// **'Chapter Complete!'**
  String get chapterComplete;

  /// No description provided for @chapterCleared.
  ///
  /// In en, this message translates to:
  /// **'Chapter Cleared!'**
  String get chapterCleared;

  /// No description provided for @bonusVocabularyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Bonus Vocabulary Challenge'**
  String get bonusVocabularyChallenge;

  /// No description provided for @vocabularyBonusDescription.
  ///
  /// In en, this message translates to:
  /// **'Practice important words from this chapter and earn bonus XP.'**
  String get vocabularyBonusDescription;

  /// No description provided for @greatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get greatJob;

  /// No description provided for @youUnderstoodTheStory.
  ///
  /// In en, this message translates to:
  /// **'You understood the story!'**
  String get youUnderstoodTheStory;

  /// No description provided for @readyForNextAdventure.
  ///
  /// In en, this message translates to:
  /// **'You are ready for the next adventure!'**
  String get readyForNextAdventure;

  /// No description provided for @bonusXpEarned.
  ///
  /// In en, this message translates to:
  /// **'Bonus XP Earned: +{xp}'**
  String bonusXpEarned(int xp);

  /// No description provided for @vocabularyBonusFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your bonus XP. Please try again.'**
  String get vocabularyBonusFailed;

  /// No description provided for @vocabularyRetryBonus.
  ///
  /// In en, this message translates to:
  /// **'Retry bonus'**
  String get vocabularyRetryBonus;

  /// No description provided for @chapterPracticeComplete.
  ///
  /// In en, this message translates to:
  /// **'Practice Complete'**
  String get chapterPracticeComplete;

  /// No description provided for @storyQuizComplete.
  ///
  /// In en, this message translates to:
  /// **'Story Quiz Complete'**
  String get storyQuizComplete;

  /// No description provided for @vocabularyChallengeComplete.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Challenge Complete'**
  String get vocabularyChallengeComplete;

  /// No description provided for @vocabularySkipped.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Challenge Skipped'**
  String get vocabularySkipped;

  /// No description provided for @xpEarned.
  ///
  /// In en, this message translates to:
  /// **'XP Earned'**
  String get xpEarned;

  /// No description provided for @wordsPracticedLabel.
  ///
  /// In en, this message translates to:
  /// **'Words Practiced'**
  String get wordsPracticedLabel;

  /// No description provided for @wordsPracticed.
  ///
  /// In en, this message translates to:
  /// **'Words Practiced: {count}'**
  String wordsPracticed(int count);

  /// No description provided for @chapterProgress.
  ///
  /// In en, this message translates to:
  /// **'Chapter Progress'**
  String get chapterProgress;

  /// No description provided for @chapterProgressCount.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} chapters complete'**
  String chapterProgressCount(int completed, int total);

  /// No description provided for @chapterProgressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get chapterProgressUnavailable;

  /// No description provided for @chapterJourneyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This chapter journey is no longer available.'**
  String get chapterJourneyUnavailable;

  /// No description provided for @storyCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Story Complete!'**
  String get storyCompletionTitle;

  /// No description provided for @storyCompletionMessage.
  ///
  /// In en, this message translates to:
  /// **'You completed the journey. You are ready for your next adventure!'**
  String get storyCompletionMessage;

  /// No description provided for @storyCompletionReturnToMap.
  ///
  /// In en, this message translates to:
  /// **'Return to Adventure Map'**
  String get storyCompletionReturnToMap;

  /// No description provided for @storyCompletionReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay Story'**
  String get storyCompletionReplay;

  /// No description provided for @storyCompletionChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters Completed'**
  String get storyCompletionChapters;

  /// No description provided for @storyCompletionWordsPracticed.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Words Practiced'**
  String get storyCompletionWordsPracticed;

  /// No description provided for @storyCompletionXpEarned.
  ///
  /// In en, this message translates to:
  /// **'Total XP Earned'**
  String get storyCompletionXpEarned;

  /// No description provided for @storyCompletionDate.
  ///
  /// In en, this message translates to:
  /// **'Completion Date'**
  String get storyCompletionDate;

  /// No description provided for @chapterListReturn.
  ///
  /// In en, this message translates to:
  /// **'Return to chapters'**
  String get chapterListReturn;

  /// No description provided for @vocabularyChallengePrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose the meaning that best matches the word.'**
  String get vocabularyChallengePrompt;

  /// No description provided for @vocabularyWhatDoesWordMean.
  ///
  /// In en, this message translates to:
  /// **'What does \"{word}\" mean?'**
  String vocabularyWhatDoesWordMean(String word);

  /// No description provided for @vocabularySubmitAnswer.
  ///
  /// In en, this message translates to:
  /// **'Submit answer'**
  String get vocabularySubmitAnswer;

  /// No description provided for @vocabularyCorrectFeedback.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get vocabularyCorrectFeedback;

  /// No description provided for @vocabularyIncorrectFeedback.
  ///
  /// In en, this message translates to:
  /// **'Not quite.'**
  String get vocabularyIncorrectFeedback;

  /// No description provided for @vocabularyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get vocabularyContinue;

  /// No description provided for @vocabularyComplete.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary challenge complete!'**
  String get vocabularyComplete;

  /// No description provided for @vocabularyBackToChapter.
  ///
  /// In en, this message translates to:
  /// **'Back to chapter'**
  String get vocabularyBackToChapter;

  /// No description provided for @vocabularyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary is not available yet.'**
  String get vocabularyUnavailable;

  /// No description provided for @libraryCompletedChapterCount.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} chapters completed'**
  String libraryCompletedChapterCount(int completed, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bik', 'en', 'tl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bik':
      return AppLocalizationsBik();
    case 'en':
      return AppLocalizationsEn();
    case 'tl':
      return AppLocalizationsTl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
