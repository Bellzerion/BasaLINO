// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class AppLocalizationsTl extends AppLocalizations {
  AppLocalizationsTl([String locale = 'tl']) : super(locale);

  @override
  String get appName => 'BasaLINO';

  @override
  String get continueLabel => 'Magpatuloy';

  @override
  String get cancelLabel => 'Kanselahin';

  @override
  String get saveLabel => 'I-save';

  @override
  String get retryLabel => 'Subukan muli';

  @override
  String get closeLabel => 'Isara';

  @override
  String get nextLabel => 'Susunod';

  @override
  String get backLabel => 'Bumalik';

  @override
  String get submitLabel => 'Isumite';

  @override
  String get loadingLabel => 'Naglo-load…';

  @override
  String get errorGeneric => 'May nangyaring mali. Pakisubukan muli.';

  @override
  String get errorNoInternet =>
      'Walang koneksyon sa internet. Suriin ang iyong network.';

  @override
  String get errorUnauthorized => 'Wala kang pahintulot na gawin ito.';

  @override
  String get authSignIn => 'Mag-sign In';

  @override
  String get authSignUp => 'Lumikha ng Account';

  @override
  String get authSignOut => 'Mag-sign Out';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authNickname => 'Palayaw';

  @override
  String get authForgotPassword => 'Nakalimutan ang password?';

  @override
  String get authResetPassword => 'I-reset ang Password';

  @override
  String get authResetPasswordSent =>
      'Naipadala ang email para i-reset ang password. Suriin ang iyong inbox.';

  @override
  String get authNoAccount => 'Wala pang account? Mag-sign up';

  @override
  String get authHaveAccount => 'Mayroon nang account? Mag-sign in';

  @override
  String get authEmailInvalid => 'Maglagay ng wastong email address.';

  @override
  String get authPasswordTooShort =>
      'Ang password ay dapat na may hindi bababa sa 8 na karakter.';

  @override
  String get authNicknameTooShort =>
      'Ang palayaw ay dapat na may hindi bababa sa 2 na karakter.';

  @override
  String get authErrorEmailInUse => 'Ginagamit na ang email na ito.';

  @override
  String get authErrorWrongPassword => 'Mali ang email o password.';

  @override
  String get authErrorUserNotFound => 'Walang account na may email na ito.';

  @override
  String get authErrorTooManyRequests =>
      'Masyadong maraming pagtatangka. Mangyaring maghintay at subukan muli.';

  @override
  String get consentTitle => 'Kailangan ang Pahintulot ng Magulang';

  @override
  String get consentBody =>
      'Ang BasaLINO ay para sa mga mag-aaral na wala pang 18 taong gulang. Ang isang magulang o tagapag-alaga ay kailangang aprubahan ang iyong account bago mo ma-access ang mga kwento at hamon.';

  @override
  String get consentPending =>
      'Ang iyong account ay naghihintay ng pahintulot ng tagapag-alaga. Hilingin sa iyong magulang o tagapag-alaga na suriin ang kanilang email.';

  @override
  String get consentContactSupport => 'Makipag-ugnayan sa suporta';

  @override
  String get profileTitle => 'Aking Profile';

  @override
  String get profileLanguagePreference => 'Wika sa Pagbabasa';

  @override
  String get profileLanguageEn => 'Ingles';

  @override
  String get profileLanguageTl => 'Tagalog';

  @override
  String get profileLanguageBik => 'Bikol';

  @override
  String get libraryTitle => 'Mga Kwento';

  @override
  String get libraryEmpty => 'Wala pang mga kwento.';

  @override
  String libraryChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na kabanata',
      one: '1 kabanata',
    );
    return '$_temp0';
  }

  @override
  String get libraryAvailableIn => 'Makukuha sa:';

  @override
  String libraryProgressLabel(int completed, int total) {
    return '$completed sa $total na kabanata';
  }

  @override
  String get chaptersTitle => 'Mga Kabanata';

  @override
  String get chapterLocked => 'Naka-lock';

  @override
  String get chapterCompleted => 'Natapos';

  @override
  String get chapterUnlocked => 'Simulan ang Pagbabasa';

  @override
  String get chapterCurrent => 'Magpatuloy';

  @override
  String get chapterLockedHint =>
      'Tapusin ang nakaraang kabanata para ma-unlock.';

  @override
  String get readerTextSizeLabel => 'Laki ng Teksto';

  @override
  String get readerVocabHintTitle => 'Talasalitaan';

  @override
  String get readerStartChallenge => 'Kumuha ng Quiz';

  @override
  String get readerAlreadyCompleted => 'Natapos ang Kabanata ✓';

  @override
  String readerChapterComplete(int xp) {
    return 'Natapos ang kabanata! Nakakuha ka ng $xp XP.';
  }

  @override
  String get challengeTitle => 'Pagsusuri sa Pagbabasa';

  @override
  String challengeQuestion(int current, int total) {
    return 'Tanong $current sa $total';
  }

  @override
  String get challengeSubmit => 'Isumite ang mga Sagot';

  @override
  String get challengeSubmitting => 'Sinusuri ang iyong mga sagot…';

  @override
  String challengeResultPass(int score) {
    return 'Magaling! Nakakuha ka ng $score%.';
  }

  @override
  String challengeResultFail(int score) {
    return 'Nakakuha ka ng $score%. Subukan muli para ma-unlock ang susunod na kabanata.';
  }

  @override
  String challengeXpEarned(int xp) {
    return '+$xp XP ang nakuha!';
  }

  @override
  String get challengeAlreadyCompleted => 'Natapos mo na ang quiz na ito.';

  @override
  String get challengeErrorNotEligible =>
      'Hindi ka karapat-dapat na sumubok ng quiz na ito.';

  @override
  String get challengeNextChapter => 'Susunod na Kabanata';

  @override
  String get challengeRetry => 'Subukan Muli';

  @override
  String get challengeBackToStory => 'Bumalik sa Kwento';

  @override
  String get progressTitle => 'Aking Pag-unlad';

  @override
  String progressXpTotal(int xp) {
    return '$xp XP na nakuha';
  }

  @override
  String get progressStoriesStarted => 'Mga kwentong sinimulan';

  @override
  String get progressChaptersCompleted => 'Mga kabanatang natapos';

  @override
  String get progressRecentAttempts => 'Mga Kamakailang Resulta ng Quiz';

  @override
  String get progressNoAttempts => 'Wala pang mga resulta ng quiz.';

  @override
  String progressAttemptScore(int score, String chapter) {
    return '$score% sa $chapter';
  }

  @override
  String get loginTagline => 'Nagiging pakikipagsapalaran ang pagbabasa.';

  @override
  String get loginIntroduction =>
      'Tuklasin ang mga kuwentong Pilipino, isang kabanata sa bawat pagkakataon.';

  @override
  String get authEmailLabel => 'Email Address';

  @override
  String get authCompleteRequired => 'Punan ang lahat ng kinakailangang field.';

  @override
  String get registerIntroduction =>
      'Sumali sa BasaLINO at simulan ang iyong pakikipagsapalaran sa pagbabasa.';

  @override
  String get authLearnerNicknameLabel => 'Palayaw ng Mag-aaral';

  @override
  String get homeStoriesUnavailable =>
      'Hindi available ang mga kuwento sa ngayon.';

  @override
  String get homeExplorer => 'Manlalakbay';

  @override
  String get homeAdventureMap => 'Mapa ng Pakikipagsapalaran';

  @override
  String get homeMoreStories => 'Iba pang kuwentong matutuklasan';

  @override
  String homeGreeting(String name) {
    return 'Kumusta, $name!';
  }

  @override
  String get homeGreetingPrompt =>
      'Handa ka na ba sa susunod mong pakikipagsapalaran?';

  @override
  String get homeAdventureFilipino => 'Pakikipagsapalaran - Kuwentong Pilipino';

  @override
  String get homeFirstChapterReady => 'Handa na ang iyong unang kabanata';

  @override
  String homeChapterProgress(int current, int total) {
    return 'Kabanata $current sa $total';
  }

  @override
  String get homeClearedStories => 'Mga kuwentong natapos';

  @override
  String get homeChapterStart => 'Simulan';

  @override
  String get homeStoryCompleted => 'Tapos na ang Kuwento';

  @override
  String get progressJourneyTitle => 'Aking Paglalakbay sa Pagkatuto';

  @override
  String progressLearner(String name) {
    return 'Mag-aaral: $name';
  }

  @override
  String get progressStoriesInProgress => 'Mga Kuwentong Binabasa';

  @override
  String get progressStartPrompt =>
      'Magsimulang magbasa ng mga kuwento para masubaybayan ang iyong progreso!';

  @override
  String progressChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na kabanata ang natapos',
      one: '1 kabanata ang natapos',
    );
    return '$_temp0';
  }

  @override
  String get progressNoQuizAttemptsRecorded =>
      'Wala pang naitalang pagsubok sa quiz.';

  @override
  String progressScoreAndXp(int score, int xp) {
    return 'Iskor: $score% • +$xp XP';
  }

  @override
  String get progressPassed => 'PUMASA';

  @override
  String get progressRetry => 'ULITIN';

  @override
  String get progressExplorer => 'Manlalakbay';

  @override
  String get progressMayonStoryTitle => 'Ang Alamat ng Bulkang Mayon';

  @override
  String get profileLearner => 'Mag-aaral';

  @override
  String get profileEnglishDescription => 'Default na nilalaman at mga quiz';

  @override
  String get profileTagalogDescription => 'Wikang Pambansa';

  @override
  String get profileBikolCentral => 'Bikol (Sentral)';

  @override
  String get profileBikolDescription => 'Salin sa Bikol Sentral';

  @override
  String get challengeIncompleteQuestions =>
      'Sagutin ang lahat ng tanong bago isumite.';

  @override
  String get challengeUnavailable =>
      'Hindi available sa ngayon ang nilalaman ng pagsusulit.';

  @override
  String challengeInstructions(int count) {
    return 'Sagutin nang tama ang lahat ng $count tanong para makakuha ng XP at ma-unlock ang susunod na kabanata.';
  }

  @override
  String challengeSubmitFailed(String error) {
    return 'Hindi naisumite: $error';
  }

  @override
  String get challengeResultAwesome => 'Napakahusay!';

  @override
  String get challengeResultKeepPracticing => 'Patuloy na magsanay!';

  @override
  String challengeResultPassDetail(int score, int correct, int total) {
    return 'Nakakuha ka ng $score% ($correct sa $total ang tama)!';
  }

  @override
  String challengeResultFailDetail(int score, int threshold) {
    return 'Nakakuha ka ng $score%. Kailangan ng hindi bababa sa $threshold% para ma-unlock ang susunod na kabanata.';
  }

  @override
  String get challengeBackToChapters => 'Bumalik sa mga Kabanata';

  @override
  String get challengeReadNextChapter => 'Basahin ang Susunod na Kabanata';

  @override
  String get readerTitle => 'Mambabasa ng Kuwento';

  @override
  String get readerAdjustTextSize => 'Ayusin ang laki ng teksto';

  @override
  String get readerSelectLanguage => 'Pumili ng Wika';

  @override
  String get readerLanguageEnglish => 'Ingles (EN)';

  @override
  String get readerLanguageTagalog => 'Tagalog (TL)';

  @override
  String get readerLanguageBikol => 'Bikol (BIK)';

  @override
  String get readerUnavailable =>
      'Hindi available sa piniling wika ang nilalaman ng kabanata.';

  @override
  String get readerReadInEnglish => 'Basahin sa Ingles';

  @override
  String get readerTranslationReview =>
      'Sinusuri pa ng mga espesyalista sa wika ang saling ito.';

  @override
  String get readerFallbackVocabularyDefinition =>
      'Mahalagang salita sa kuwento.';

  @override
  String get chapterListDescription =>
      'Basahin ang mga kabanata ayon sa pagkakasunod-sunod at pumasa sa pagsusuri sa pagbasa para ma-unlock ang susunod na kabanata.';

  @override
  String chapterError(String error) {
    return 'Error: $error';
  }

  @override
  String get chapterEmpty => 'Walang nahanap na kabanata.';

  @override
  String chapterLabel(int number) {
    return 'Kabanata $number';
  }

  @override
  String get chapterStatusUnlocked => 'Naka-unlock';

  @override
  String get chapterQuizUnlockHint =>
      'Tapusin ang quiz sa naunang kabanata para ma-unlock ito.';

  @override
  String get chapterFallbackStory => 'Kuwento';

  @override
  String get clearedStoriesTitle => 'Mga Kuwentong Natapos';

  @override
  String get clearedStoriesLoadError =>
      'Hindi ma-load ang mga kuwentong natapos mo.';

  @override
  String clearedStoryChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na kabanata ang natapos',
      one: '1 kabanata ang natapos',
    );
    return '$_temp0';
  }

  @override
  String get clearedStoriesEmptyTitle => 'Wala ka pang natatapos na kuwento';

  @override
  String get clearedStoriesEmptyDescription =>
      'Tapusin ang bawat kabanata at pagsusuri sa pagbasa nito para maidagdag ang kuwento sa iyong koleksiyon.';

  @override
  String get clearedStoriesContinueReading => 'Magpatuloy sa pagbabasa';

  @override
  String get consentInformation =>
      'Seryoso ang BasaLINO sa kaligtasan at pagkapribado ng mga bata. Nagpadala kami ng email sa nakarehistrong tagapag-alaga mo na may mga tagubilin para aprubahan ang iyong access bilang mag-aaral.';

  @override
  String get consentApprovalStillPending =>
      'Nasuri na ang status ng pahintulot: hinihintay pa rin.';

  @override
  String get consentCheckApproval => 'Suriin ang Status ng Pahintulot';

  @override
  String get libraryAppBarTitle => 'Aklatan ng BasaLINO';

  @override
  String get libraryProgressTooltip => 'Aking Pag-unlad';

  @override
  String get libraryProfileTooltip => 'Profile at Wika';

  @override
  String libraryLoadError(String error) {
    return 'Error sa pag-load ng mga kuwento: $error';
  }

  @override
  String get readerCheckKnowledge => 'Suriin ang Kaalaman';

  @override
  String get knowledgeStoryQuiz => 'Pagsusulit sa Kuwento';

  @override
  String get knowledgeVocabularyChallenge => 'Hamon sa Bokabularyo';

  @override
  String get knowledgeStoryQuizDescription =>
      'Subukan ang nalaman mo sa kabanata.';

  @override
  String get knowledgeVocabularyChallengeDescription =>
      'Sanayin ang mahahalagang salita sa kuwento.';

  @override
  String get quizComplete => 'Tapos na ang Pagsusulit!';

  @override
  String quizScore(int correct, int total) {
    return 'Iskor: $correct/$total';
  }

  @override
  String get startVocabularyChallenge => 'Simulan ang Hamon sa Bokabularyo';

  @override
  String get vocabularyChapterPractice =>
      'Sanayin ang mahahalagang salita mula sa kabanatang ito.';

  @override
  String get vocabularySkipForNow => 'Laktawan muna';

  @override
  String get continueAdventure => 'Ipagpatuloy ang Pakikipagsapalaran';

  @override
  String get chapterComplete => 'Tapos na ang Kabanata!';

  @override
  String get chapterCleared => 'Nalampasan ang Kabanata!';

  @override
  String get bonusVocabularyChallenge => 'Bonus na Hamon sa Bokabularyo';

  @override
  String get vocabularyBonusDescription =>
      'Sanayin ang mahahalagang salita mula sa kabanatang ito at makakuha ng bonus XP.';

  @override
  String get greatJob => 'Magaling!';

  @override
  String get youUnderstoodTheStory => 'Naunawaan mo ang kuwento!';

  @override
  String get readyForNextAdventure =>
      'Handa ka na sa susunod na pakikipagsapalaran!';

  @override
  String bonusXpEarned(int xp) {
    return 'Bonus XP na Nakuha: +$xp';
  }

  @override
  String get vocabularyBonusFailed =>
      'Hindi namin na-save ang iyong bonus XP. Subukan muli.';

  @override
  String get vocabularyRetryBonus => 'Subukan muli ang bonus';

  @override
  String get chapterPracticeComplete => 'Tapos na ang Pagsasanay';

  @override
  String get storyQuizComplete => 'Tapos na ang Pagsusulit sa Kuwento';

  @override
  String get vocabularyChallengeComplete => 'Tapos na ang Hamon sa Bokabularyo';

  @override
  String get vocabularySkipped => 'Nilaktawan ang Hamon sa Bokabularyo';

  @override
  String get xpEarned => 'XP na Nakuha';

  @override
  String get wordsPracticedLabel => 'Mga Salitang Napagsanayan';

  @override
  String wordsPracticed(int count) {
    return 'Mga Salitang Napagsanayan: $count';
  }

  @override
  String get chapterProgress => 'Pag-unlad sa Kabanata';

  @override
  String chapterProgressCount(int completed, int total) {
    return '$completed sa $total kabanata ang natapos';
  }

  @override
  String get chapterProgressUnavailable => 'Hindi available';

  @override
  String get chapterJourneyUnavailable =>
      'Hindi na available ang paglalakbay sa kabanatang ito.';

  @override
  String get storyCompletionTitle => 'Tapos na ang Kuwento!';

  @override
  String get storyCompletionMessage =>
      'Natapos mo ang paglalakbay na ito. Handa ka na sa susunod mong pakikipagsapalaran!';

  @override
  String get storyCompletionReturnToMap =>
      'Bumalik sa Mapa ng Pakikipagsapalaran';

  @override
  String get storyCompletionReplay => 'Ulitin ang Kuwento';

  @override
  String get storyCompletionChapters => 'Mga Kabanatang Natapos';

  @override
  String get storyCompletionWordsPracticed => 'Mga Salitang Pinagsanayan';

  @override
  String get storyCompletionXpEarned => 'Kabuuang XP na Nakuha';

  @override
  String get storyCompletionDate => 'Petsa ng Pagtatapos';

  @override
  String get chapterListReturn => 'Bumalik sa mga kabanata';

  @override
  String get vocabularyChallengePrompt =>
      'Piliin ang kahulugang pinakamalapit sa salita.';

  @override
  String vocabularyWhatDoesWordMean(String word) {
    return 'Ano ang ibig sabihin ng \"$word\"?';
  }

  @override
  String get vocabularySubmitAnswer => 'Isumite ang sagot';

  @override
  String get vocabularyCorrectFeedback => 'Tama!';

  @override
  String get vocabularyIncorrectFeedback => 'Hindi pa tama.';

  @override
  String get vocabularyContinue => 'Magpatuloy';

  @override
  String get vocabularyComplete => 'Tapos na ang hamon sa bokabularyo!';

  @override
  String get vocabularyBackToChapter => 'Bumalik sa kabanata';

  @override
  String get vocabularyUnavailable => 'Hindi pa available ang bokabularyo.';

  @override
  String libraryCompletedChapterCount(int completed, int total) {
    return '$completed sa $total na kabanata ang natapos';
  }
}
