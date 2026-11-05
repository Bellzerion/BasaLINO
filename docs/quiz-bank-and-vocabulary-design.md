# BasaLINO quiz banks and vocabulary activities

## Scope and design decisions

This plan strengthens content without changing BasaLINO's story, route, Riverpod, or offline-first architecture. It extends the existing `ChallengeRepository`, `LocalChallengeRepository`, `FirebaseChallengeRepository`, `ProgressRepository`, and the chapter vocabulary already rendered by `ReaderScreen`.

The current data shape has one complete challenge document per chapter and language. `getChallenge` returns that document unchanged, and the local mock validates localized answer strings in `challenge_keys.json`. This makes a two-question challenge easy to render, but it cannot produce varied attempts safely. The new shape treats that document as a *bank*, selects an attempt from it, and validates stable option IDs.

Use stable IDs across translations. A question such as `mayon_ch1_q01` identifies the same learning target in English, Filipino, and Bikol; only its prompt and options are translated. Never use displayed answer text as the saved answer or answer key.

## Content targets

Start each chapter with **12 reviewed questions**. This is inside the requested 8--15 range and permits several varied five-question attempts. A bank must never contain fewer than 8 published questions; 15 is a practical cap for the first release. Add questions in groups of 3 after content review rather than replacing existing IDs.

| Story / chapter | Current English bank | Release target | Suggested mix |
| --- | ---: | ---: | --- |
| Ibalong 1 | 3 | 12 | 5 literal, 3 sequence/cause, 2 vocabulary-in-context, 2 inference |
| Ibalong 2 | 2 | 12 | 5 literal, 3 sequence/cause, 2 vocabulary-in-context, 2 inference |
| Ibalong 3 | 2 | 12 | 5 literal, 3 sequence/cause, 2 vocabulary-in-context, 2 inference |
| Mayon 1 | 2 | 12 | 5 literal, 3 sequence/cause, 2 vocabulary-in-context, 2 inference |
| Mayon 2 | 2 | 12 | 5 literal, 3 sequence/cause, 2 vocabulary-in-context, 2 inference |
| Mayon 3 | 2 | 12 | 5 literal, 3 sequence/cause, 2 vocabulary-in-context, 2 inference |

Every published question must have English, Filipino (`tl`), and Bikol (`bik`) text reviewed by a fluent educator. Until that is true, use the current explicit English fallback and mark the source translation `needsReview`; do not mix English options with a localized prompt.

For each bank, include all of the following before adding harder inference questions:

1. character, setting, event, and outcome recall;
2. chronology and cause/effect;
3. one question for each bracketed vocabulary word or an equivalent context item; and
4. a small number of evidence-based inference questions with a clearly defensible answer.

Avoid trick questions, negative wording, and distractors that are implausible, culturally misleading, or merely grammatically different from the answer.

## Version-2 bank schema

Store one language record per chapter, retaining the repository's current lookup pattern. `questionSetId` and every question/option ID are shared by its translations. The public file has no correct answer; the local development key file and Firebase callable function do.

```json
{
  "schemaVersion": 2,
  "id": "qbank_mayon_ch1_en_v1",
  "questionSetId": "mayon_ch1",
  "chapterId": "mayon_ch1",
  "languageCode": "en",
  "version": 1,
  "attemptPolicy": {
    "questionsPerAttempt": 5,
    "minimumPublishedQuestions": 8,
    "recentQuestionExclusion": 5
  },
  "questions": [
    {
      "id": "mayon_ch1_q01",
      "skill": "literal_recall",
      "difficulty": 1,
      "vocabularyIds": [],
      "prompt": "What does the name ‘Magayon’ mean in Bikol?",
      "options": [
        { "id": "a", "text": "Strong" },
        { "id": "b", "text": "Beautiful" },
        { "id": "c", "text": "Gentle" },
        { "id": "d", "text": "Golden" }
      ]
    },
    {
      "id": "mayon_ch1_q07",
      "skill": "vocabulary_in_context",
      "difficulty": 2,
      "vocabularyIds": ["mayon_ch1_captivated"],
      "prompt": "Panganoron was ‘captivated’ by Magayon. What does captivated mean here?",
      "options": [
        { "id": "a", "text": "Frightened and ready to run" },
        { "id": "b", "text": "Attracted and deeply interested" },
        { "id": "c", "text": "Confused by a map" },
        { "id": "d", "text": "Ordered to leave" }
      ]
    }
  ]
}
```

The matching development-only answer file is keyed by bank ID and question ID, with option IDs rather than strings:

```json
{
  "qbank_mayon_ch1_en_v1": {
    "mayon_ch1_q01": "b",
    "mayon_ch1_q07": "b"
  }
}
```

Production Firestore documents can retain this public shape in `challenges/{bankId}`. Store the answer key in the protected server-side content source used by `submitAttempt`; it must not be readable by clients. The callable receives `bankId`, `bankVersion`, selected `questionIds`, and `{questionId: optionId}` answers, and rejects a question that is not in the submitted attempt.

## Flutter integration

Suggested locations (names can be adopted incrementally):

```text
assets/data/question_banks/
  ibalong_ch1.json        # en/tl/bik records or a single translations object
  ibalong_ch2.json
  ibalong_ch3.json
  mayon_ch1.json
  mayon_ch2.json
  mayon_ch3.json
assets/data/question_keys.dev.json
assets/data/vocabulary.json
lib/core/models/question_bank_model.dart
lib/core/models/quiz_attempt_model.dart
lib/core/models/vocabulary_item_model.dart
lib/core/models/vocabulary_activity_result_model.dart
lib/core/services/local_challenge_repository.dart
lib/core/services/local_progress_repository.dart
```

If files move below `assets/data/`, list each directory/file in `pubspec.yaml`; Flutter asset declarations should not assume recursive directory inclusion. An alternative minimal migration is to retain `assets/data/challenges.json`, replace its records with the V2 shape, and rename only after the repository has been migrated.

Add these concepts to the existing models, keeping `ChallengeScreen`'s responsibility unchanged:

* `QuestionBankModel`: `id`, `questionSetId`, `chapterId`, `languageCode`, `version`, `attemptPolicy`, `questions`.
* `QuestionModel`: `id`, `skill`, `difficulty` (1--3 initially), `vocabularyIds`, `prompt`, `options`.
* `QuestionOptionModel`: `id`, `text`.
* `QuizAttemptModel`: `attemptId`, `bankId`, `bankVersion`, `chapterId`, `languageCode`, `questionIds`, `answers`, `score`, `passed`, `startedAt`, `completedAt`.

Change repository retrieval from `getChallenge(chapterId, languageCode)` to either `createAttempt(...)` or a backward-compatible `getChallenge(..., recentQuestionIds: ...)` that returns a selected five-question `ChallengeModel`. The first option is preferable because it creates an immutable attempt snapshot before the learner answers. `submitAttempt` must accept that snapshot/attempt ID and option IDs. Continue using the existing pass threshold, XP, and chapter unlocking behavior.

`LocalChallengeRepository` loads/caches the bank asset exactly as it currently does. `FirebaseChallengeRepository` retrieves the matching bank document, creates the same deterministic selection client-side or through the callable, and sends the snapshot to the callable. The screens need only render `question.prompt` and `option.text`; selection becomes `questionId -> optionId`.

## Five-question selection and repeat control

At attempt start:

1. Load the selected-language bank, falling back to English only if the entire locale bank is unavailable.
2. Read the learner's last five question IDs for that chapter and language. This is an exclusion window, not a permanent ban.
3. Build `eligible = bank.questions - recentIds`. If it has at least five items, sample five without replacement. Otherwise, first use all eligible items, then fill the remaining places by least-recently-used questions from the bank.
4. Shuffle selected questions and shuffle each question's displayed options. Keep the option ID with its text.
5. Persist the ordered selected IDs immediately as the attempt snapshot. Grade only those IDs.

Use a seeded random value saved with the attempt (`selectionSeed`) for reproducible debugging; use `Random.secure()` where available to create the seed. Do not persist only the score: an update to a bank must not change the questions or answer key used to grade an in-progress/recent attempt.

With 12 questions and a five-question exclusion window, the next attempt can use seven unseen questions. The third attempt can reintroduce questions, but least-recently-used ordering prevents the same combination from recurring. For a future larger bank, retain this policy and raise the exclusion window to the number of questions in the previous one or two attempts.

## Vocabulary content model

Promote the existing inline `vocabularyHints` to reusable vocabulary records. `chapters.json` can continue to hold the bracketed text markers during the migration; each hint gains a stable `id` that points to the shared record.

```json
{
  "id": "mayon_ch1_captivated",
  "chapterId": "mayon_ch1",
  "languageCode": "en",
  "word": "captivated",
  "partOfSpeech": "verb",
  "definition": "Attracted and held someone's interest or attention.",
  "contextSentence": "Panganoron was captivated by Magayon's beauty and kindness.",
  "translations": {
    "tl": { "word": "nabighani", "definition": "Naakit at nahawakan ang interes at atensiyon." },
    "bik": { "word": "nabighani", "definition": "Naakit asin nahawakan an interes asin atensiyon." }
  },
  "tags": ["story-word", "emotion"],
  "difficulty": 1
}
```

Make a chapter's 2--3 existing highlighted words its first vocabulary set. Add only 3--5 new reviewed items per chapter so a learner can encounter, match, and review them without overload. IDs, context sentences, definitions, and translation links make each activity localizable without branching UI logic.

## Vocabulary activities

### 1. Word-to-Meaning Match — build first

**Goal:** Build form-to-meaning knowledge of the chapter's highlighted vocabulary.

**Flow:** After reading or from a “Words to practise” button, show one word and three short meaning cards. The learner taps one answer, sees immediate corrective feedback with the context sentence, then continues for 3--5 items. A retry shows only missed items once.

**Data:** `VocabularyItemModel` needs `id`, displayed word, definition, part of speech, context sentence, and two same-part-of-speech plausible distractor definitions. Keep distractors as localized authored text, not generated text.

**Tracking:** Save item ID, activity type, correct/incorrect, attempt count, and completion time. Maintain `timesSeen`, `timesCorrect`, `lastSeenAt`, and `lastResult`; award completion XP separately from quiz XP if desired. Completion must never gate chapter progression.

### 2. Translation Match

**Goal:** Connect the reading language with the learner's support language while avoiding word-for-word assumptions.

**Flow:** Present a source word plus its short context; the learner picks its equivalent in the selected support language. Follow with the definition/context as feedback. Use a language-pair selector only when both translations are reviewed.

**Data:** One vocabulary concept ID, language-specific `word`, definition, and optionally `translationEquivalent` plus `translationNote` for imperfect equivalents. Distractors must be from the same part of speech and target language.

**Tracking:** Add `sourceLanguage`, `targetLanguage`, and `conceptId` to the common activity result. Store performance by concept, not only surface form, so English-to-Bikol and Bikol-to-English practice accumulate together.

### 3. Vocabulary Review

**Goal:** Reinforce retention through brief retrieval after reading, without a new game mechanic.

**Flow:** A compact card shows the word, part of speech, definition, and story sentence; “I know this” / “Practise again” records the learner's self-report. A second pass can turn a card into one Word-to-Meaning question. Show 3 cards at a time, ordered from weakest/recently missed to newest.

**Data:** The core vocabulary item only; no distractors are required for passive review. `reviewMode` allows recognition now and recall later.

**Tracking:** Save `reviewedAt`, `selfRating` (know/practise), and optional recall result. Do not count self-rating as mastery; show it separately from scored activity outcomes.

### 4. Context-Meaning Identification

**Goal:** Teach learners to infer a word's meaning from a meaningful sentence, the strongest bridge from vocabulary to reading comprehension.

**Flow:** Display a story sentence with the target word highlighted and three meanings. The learner chooses the best meaning, then sees a short explanation pointing to a contextual clue. Begin only after the word has appeared in Word-to-Meaning Match.

**Data:** A localized `contextSentence`, target-word span (or marker), correct meaning, contextual-clue explanation, and three options. `difficulty` can represent clue clarity: direct synonym (1), strong situational clue (2), indirect inference (3).

**Tracking:** Use the common result plus `mode: contextMeaning` and `difficulty`. Keep errors; an incorrect contextual inference is especially useful for later review and eventual adaptive selection.

## Offline progress and migration

Keep one versioned SharedPreferences document. Bump `basalino.progress.v1` to a version-2 envelope or add a new `basalino.learning-progress.v2` key; migrate old story progress and recent quiz summary unchanged. Do not make existing learners repeat unlocked chapters.

Add a bounded `quizAttempts` history (for example, most recent 20 attempts per learner) containing the attempt snapshot's question IDs and answers. Add a bounded `vocabularyProgress` map keyed by `conceptId`/`vocabularyItemId`. Prune oldest full attempts only after their question IDs have aged out of the repeat window; retain aggregate vocabulary counters. Existing `RecentAttemptModel` can remain as the progress-screen summary, while `QuizAttemptModel` is the audit/selection record.

Recommended shared vocabulary result fields:

```text
attemptId, activityType, chapterId, vocabularyItemId, conceptId,
languageCode, sourceLanguage?, targetLanguage?, correct?, attempts,
startedAt, completedAt
```

For privacy and offline resilience, keep this on device with the rest of progress. A later Firebase sync can use the same IDs and payloads without reworking the activity UI.

## Implementation order

1. Finalize and educator-review 12 questions and 2--5 vocabulary records for each of Mayon chapters 1--3; then bring Ibalong banks to the same standard.
2. Add V2 bank models, stable option IDs, development answer keys, and bank-version validation. Write parsing and grading tests.
3. Implement attempt creation, five-question selection, question/option shuffling, and persisted recent question IDs. Test no duplicates within an attempt, the five-question exclusion rule, fallback behavior, and exact score/XP calculation.
4. Update the local and Firebase repositories and then migrate `ChallengeScreen` to option IDs. Preserve current routes, completion, XP, and unlock behavior.
5. Build Word-to-Meaning Match using the current chapter vocabulary hints; add its local progress records and localisation strings.
6. Add Vocabulary Review, then Translation Match after language-equivalent review, then Context-Meaning Identification.

## Priorities and adaptive-difficulty compatibility

Build **Word-to-Meaning Match first**. It has the highest educational value for the least engineering effort because BasaLINO already has chapter-specific words, definitions, localized reader text, touch-friendly multiple choice, repositories, and local persistence. It needs no drag-and-drop, timers, audio, network access, or new navigation paradigm.

**Context-Meaning Identification** best supports a later adaptive system: its explicit skill tag, difficulty level, and item-level errors distinguish recognition from contextual inference. The same bank metadata (`skill`, `difficulty`, `vocabularyIds`, stable IDs, timestamps, and per-item outcomes) is sufficient for a future selector to choose practice by evidence. That future work should only change selection policy; it does not require a data-model rewrite or any AI/speech feature.
