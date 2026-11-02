// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bikol (`bik`).
class AppLocalizationsBik extends AppLocalizations {
  AppLocalizationsBik([String locale = 'bik']) : super(locale);

  @override
  String get appName => 'BasaLINO';

  @override
  String get continueLabel => 'Padagos';

  @override
  String get cancelLabel => 'Kanselaon';

  @override
  String get saveLabel => 'I-save';

  @override
  String get retryLabel => 'Subukan giraray';

  @override
  String get closeLabel => 'Isara';

  @override
  String get nextLabel => 'Sunod';

  @override
  String get backLabel => 'Bumalik';

  @override
  String get submitLabel => 'Ipadara';

  @override
  String get loadingLabel => 'Naglo-load…';

  @override
  String get errorGeneric => 'May nangyari. Subukan giraray.';

  @override
  String get errorNoInternet =>
      'Mayong koneksyon sa internet. Suriin an imo network.';

  @override
  String get errorUnauthorized => 'Dai ka awtorisado na gibohon ini.';

  @override
  String get authSignIn => 'Mag-sign In';

  @override
  String get authSignUp => 'Gumibo nin Account';

  @override
  String get authSignOut => 'Mag-sign Out';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authNickname => 'Palayaw';

  @override
  String get authForgotPassword => 'Nalingawan an password?';

  @override
  String get authResetPassword => 'I-reset an Password';

  @override
  String get authResetPasswordSent =>
      'Naipadara na an email para i-reset an password. Suriin an imo inbox.';

  @override
  String get authNoAccount => 'Mayong account? Mag-sign up';

  @override
  String get authHaveAccount => 'Igwa nang account? Mag-sign in';

  @override
  String get authEmailInvalid => 'Maglagay nin tamang email address.';

  @override
  String get authPasswordTooShort =>
      'An password dapat may 8 man sanang karakter.';

  @override
  String get authNicknameTooShort =>
      'An palayaw dapat may 2 man sanang karakter.';

  @override
  String get authErrorEmailInUse => 'Ginagamit na ini na email.';

  @override
  String get authErrorWrongPassword => 'Salang email o password.';

  @override
  String get authErrorUserNotFound => 'Mayong account na igwa kaining email.';

  @override
  String get authErrorTooManyRequests =>
      'Dakul na pagsubuk. Maghuwat asin subukan giraray.';

  @override
  String get consentTitle => 'Kaipuhan an Permiso nin Maggurang';

  @override
  String get consentBody =>
      'An BasaLINO para sa mga estudyante na mas bata sa 18 taon. An maggurang o tagapag-alaga dapat aprubahan an imo account bago ka maka-access kan mga istorya.';

  @override
  String get consentPending =>
      'An imo account naghihulat kan permiso kan tagapag-alaga. Pakihingi sa imo maggurang na suriin an saindang email.';

  @override
  String get consentContactSupport => 'Makipag-ugnayan sa suporta';

  @override
  String get profileTitle => 'Sakong Profile';

  @override
  String get profileLanguagePreference => 'Lenggwahe sa Pagbasa';

  @override
  String get profileLanguageEn => 'Ingles';

  @override
  String get profileLanguageTl => 'Tagalog';

  @override
  String get profileLanguageBik => 'Bikol';

  @override
  String get libraryTitle => 'Mga Istorya';

  @override
  String get libraryEmpty => 'Mayong mga istorya pa.';

  @override
  String libraryChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na kapitulo',
      one: '1 kapitulo',
    );
    return '$_temp0';
  }

  @override
  String get libraryAvailableIn => 'Maabot sa:';

  @override
  String libraryProgressLabel(int completed, int total) {
    return '$completed sa $total na kapitulo';
  }

  @override
  String get chaptersTitle => 'Mga Kapitulo';

  @override
  String get chapterLocked => 'Naka-lock';

  @override
  String get chapterCompleted => 'Natapos';

  @override
  String get chapterUnlocked => 'Magtukdo';

  @override
  String get chapterCurrent => 'Padagos';

  @override
  String get chapterLockedHint =>
      'Tapuson an nakaaging kapitulo para ma-unlock.';

  @override
  String get readerTextSizeLabel => 'Sukat kan Teksto';

  @override
  String get readerVocabHintTitle => 'Bokabularyo';

  @override
  String get readerStartChallenge => 'Kumuha nin Quiz';

  @override
  String get readerAlreadyCompleted => 'Natapos an Kapitulo ✓';

  @override
  String readerChapterComplete(int xp) {
    return 'Natapos an kapitulo! Nakakuha ka nin $xp XP.';
  }

  @override
  String get challengeTitle => 'Pagsuri sa Pagbasa';

  @override
  String challengeQuestion(int current, int total) {
    return 'Hapot $current sa $total';
  }

  @override
  String get challengeSubmit => 'Ipadara an mga Simbag';

  @override
  String get challengeSubmitting => 'Sinusuri an imo mga simbag…';

  @override
  String challengeResultPass(int score) {
    return 'Maray! Nakakuha ka nin $score%.';
  }

  @override
  String challengeResultFail(int score) {
    return 'Nakakuha ka nin $score%. Subukan giraray para ma-unlock an sunod na kapitulo.';
  }

  @override
  String challengeXpEarned(int xp) {
    return '+$xp XP an nakua!';
  }

  @override
  String get challengeAlreadyCompleted => 'Natapos mo na ini na quiz.';

  @override
  String get challengeErrorNotEligible =>
      'Dai ka karapat-dapat na sumubok kaining quiz.';

  @override
  String get challengeNextChapter => 'Sunod na Kapitulo';

  @override
  String get challengeRetry => 'Subukan Giraray';

  @override
  String get challengeBackToStory => 'Bumalik sa Istorya';

  @override
  String get progressTitle => 'Sakong Pag-asenso';

  @override
  String progressXpTotal(int xp) {
    return '$xp XP na nakuha';
  }

  @override
  String get progressStoriesStarted => 'Mga istoryang sinimulan';

  @override
  String get progressChaptersCompleted => 'Mga kapitulong natapos';

  @override
  String get progressRecentAttempts => 'Mga Kaibabang Resulta nin Quiz';

  @override
  String get progressNoAttempts => 'Mayong mga resulta pa.';

  @override
  String progressAttemptScore(int score, String chapter) {
    return '$score% sa $chapter';
  }

  @override
  String get loginTagline => 'An pagbasa nagigin pakikipagsapalaran.';

  @override
  String get loginIntroduction =>
      'Diskubrehon an mga istoryang Pilipino, sarong kapitulo sa kada pagkakataon.';

  @override
  String get authEmailLabel => 'Email Address';

  @override
  String get authCompleteRequired => 'Pakiaran an gabos na kaipuhan na field.';

  @override
  String get registerIntroduction =>
      'Mag-iba sa BasaLINO asin umagihan an saimong pakikipagsapalaran sa pagbasa.';

  @override
  String get authLearnerNicknameLabel => 'Palayaw kan Estudyante';

  @override
  String get homeStoriesUnavailable =>
      'Dai pa maabot an mga istorya sa ngunyan.';

  @override
  String get homeExplorer => 'Parasiyasat';

  @override
  String get homeAdventureMap => 'Mapa kan Pakikipagsapalaran';

  @override
  String get homeMoreStories => 'Dugang pang mga istoryang sisiyasaton';

  @override
  String homeGreeting(String name) {
    return 'Kumusta, $name!';
  }

  @override
  String get homeGreetingPrompt =>
      'Handa ka na sa sunod mong pakikipagsapalaran?';

  @override
  String get homeAdventureFilipino => 'Pakikipagsapalaran - Istoryang Pilipino';

  @override
  String get homeFirstChapterReady => 'Handa na an enot mong kapitulo';

  @override
  String homeChapterProgress(int current, int total) {
    return 'Kapitulo $current sa $total';
  }

  @override
  String get homeClearedStories => 'Mga istoryang natapos';

  @override
  String get homeChapterStart => 'Magpoon';

  @override
  String get progressJourneyTitle => 'Sakong Pag-agih sa Pag-adal';

  @override
  String progressLearner(String name) {
    return 'Estudyante: $name';
  }

  @override
  String get progressStoriesInProgress => 'Mga Istoryang Binabasa';

  @override
  String get progressStartPrompt =>
      'Magpoon magbasa nin mga istorya tanganing masubaybayan an saimong pag-uswag!';

  @override
  String progressChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'natapos an $count na kapitulo',
      one: 'natapos an 1 kapitulo',
    );
    return '$_temp0';
  }

  @override
  String get progressNoQuizAttemptsRecorded =>
      'Mayong nairekord na pagsubok sa quiz.';

  @override
  String progressScoreAndXp(int score, int xp) {
    return 'Iskor: $score% • +$xp XP';
  }

  @override
  String get progressPassed => 'NAKAPASA';

  @override
  String get progressRetry => 'ULITON';

  @override
  String get progressExplorer => 'Parasiyasat';

  @override
  String get progressMayonStoryTitle => 'An Alamat kan Bulkan Mayon';

  @override
  String get profileLearner => 'Estudyante';

  @override
  String get profileEnglishDescription => 'Default na mga laog asin quiz';

  @override
  String get profileTagalogDescription => 'Wikang Pambansa';

  @override
  String get profileBikolCentral => 'Bikol (Sentral)';

  @override
  String get profileBikolDescription => 'Hubad sa Bikol Sentral';

  @override
  String get challengeIncompleteQuestions =>
      'Pakisimbagan an gabos na hapot bago ipadara.';

  @override
  String get challengeUnavailable =>
      'Dai pa maabot an laog kan pagsulay sa ngunyan.';

  @override
  String challengeInstructions(int count) {
    return 'Simbagan nin tama an gabos na $count hapot tanganing makakuha nin XP asin ma-unlock an sunod na kapitulo.';
  }

  @override
  String challengeSubmitFailed(String error) {
    return 'Dai naipadara: $error';
  }

  @override
  String get challengeResultAwesome => 'Marhay na marhay!';

  @override
  String get challengeResultKeepPracticing => 'Padagos na magpraktis!';

  @override
  String challengeResultPassDetail(int score, int correct, int total) {
    return 'Nakakuha ka nin $score% ($correct sa $total an tama)!';
  }

  @override
  String challengeResultFailDetail(int score, int threshold) {
    return 'Nakakuha ka nin $score%. Kaipuhan nin labing menos $threshold% tanganing ma-unlock an sunod na kapitulo.';
  }

  @override
  String get challengeBackToChapters => 'Bumalik sa mga Kapitulo';

  @override
  String get challengeReadNextChapter => 'Basahon an Sunod na Kapitulo';

  @override
  String get readerTitle => 'Parabasa nin Istorya';

  @override
  String get readerAdjustTextSize => 'Ayuson an sukat kan teksto';

  @override
  String get readerSelectLanguage => 'Pumili nin Lenggwahe';

  @override
  String get readerLanguageEnglish => 'Ingles (EN)';

  @override
  String get readerLanguageTagalog => 'Tagalog (TL)';

  @override
  String get readerLanguageBikol => 'Bikol (BIK)';

  @override
  String get readerUnavailable =>
      'Dai maabot sa piniling lenggwahe an laog kan kapitulo.';

  @override
  String get readerReadInEnglish => 'Basahon sa Ingles';

  @override
  String get readerTranslationReview =>
      'Pig-usisa pa kan mga espesyalista sa lenggwahe an hubad na ini.';

  @override
  String get readerFallbackVocabularyDefinition =>
      'Mahalagang tataramon sa istorya.';

  @override
  String get chapterListDescription =>
      'Basahon an mga kapitulo sunod sa pagkasunod-sunod asin ipasar an pagsuri sa pagbasa tanganing ma-unlock an sunod na kapitulo.';

  @override
  String chapterError(String error) {
    return 'Error: $error';
  }

  @override
  String get chapterEmpty => 'Mayong nahanap na kapitulo.';

  @override
  String chapterLabel(int number) {
    return 'Kapitulo $number';
  }

  @override
  String get chapterStatusUnlocked => 'Naka-unlock';

  @override
  String get chapterQuizUnlockHint =>
      'Tapuson an quiz kan nakaaging kapitulo tanganing ma-unlock ini.';

  @override
  String get chapterFallbackStory => 'Istorya';

  @override
  String get clearedStoriesTitle => 'Mga Istoryang Natapos';

  @override
  String get clearedStoriesLoadError =>
      'Dai ma-load an mga istoryang natapos mo.';

  @override
  String clearedStoryChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'natapos an $count na kapitulo',
      one: 'natapos an 1 kapitulo',
    );
    return '$_temp0';
  }

  @override
  String get clearedStoriesEmptyTitle => 'Mayong istoryang natapos pa';

  @override
  String get clearedStoriesEmptyDescription =>
      'Tapuson an kada kapitulo asin an pagsuri sa pagbasa kaini tanganing maidugang an istorya sa saimong koleksyon.';

  @override
  String get clearedStoriesContinueReading => 'Magpadagos sa pagbasa';

  @override
  String get consentInformation =>
      'Seryoso an BasaLINO sa kaligtasan asin pribasidad kan mga aki. Nagpadara nin email sa rehistradong tagapag-ataman mo na igwa nin mga instruksiyon tanganing aprobahan an access mo bilang estudyante.';

  @override
  String get consentApprovalStillPending =>
      'Nasuri na an status kan permiso: naghahalat pa.';

  @override
  String get consentCheckApproval => 'Suriin an Status kan Permiso';

  @override
  String get libraryAppBarTitle => 'Aklatan nin BasaLINO';

  @override
  String get libraryProgressTooltip => 'Sakong Pag-asenso';

  @override
  String get libraryProfileTooltip => 'Profile asin Lenggwahe';

  @override
  String libraryLoadError(String error) {
    return 'Error sa pag-load nin mga istorya: $error';
  }

  @override
  String libraryCompletedChapterCount(int completed, int total) {
    return '$completed sa $total na kapitulo an natapos';
  }
}
