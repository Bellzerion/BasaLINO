# BasaLINO Cloud Firestore Data Model

This document outlines the Firestore collections and document schema for BasaLINO.

---

### 1. `users` Collection
Stores the canonical learner profile and the server-maintained XP projection.

- **Document ID**: `uid` (Firebase Auth UID)
- **Fields**:
  - `uid` (string): Must match the document ID.
  - `email` (string): Registered email address.
  - `displayName` (string, optional): Firebase Auth display name.
  - `preferredLanguage` (string): `'en' | 'tl' | 'bik'`.
  - `approvalStatus` (string): `'pending' | 'approved' | 'rejected'`. Client bootstrap must use `pending`; trusted server/admin logic owns transitions.
  - `createdAt` (timestamp): Account creation timestamp.
  - `totalXp` (integer, server-maintained): Added/updated by trusted Cloud Functions; omitted from client profile creation.

Legacy profiles may still contain `nickname`; it is read as `displayName` for
compatibility only. New writers do not use it.

---

### 2. `stories` Collection
Stores published stories and cultural epics.

- **Document ID**: `storyId` (e.g., `'ibalong'`, `'mayon'`)
- **Fields**:
  - `titleEn` (string): English reference title.
  - `descriptionEn` (string): Brief English summary.
  - `availableLanguages` (array of strings): e.g. `['en', 'tl', 'bik']`.
  - `chapterCount` (number): Total chapters in this story.
  - `coverImageAsset` (string): Path to local or remote illustration asset.

---

### 3. `chapters` Collection
Metadata for each chapter in a story.

- **Document ID**: `chapterId` (e.g., `'ibalong_ch1'`)
- **Fields**:
  - `storyId` (string): References parent story.
  - `orderIndex` (number): 0-indexed reading sequence.

---

### 4. `chapterTranslations` Collection
Holds localized narrative text, paragraphs, and vocabulary hints.

- **Document ID**: `${chapterId}_${languageCode}` (e.g. `'ibalong_ch1_en'`)
- **Fields**:
  - `chapterId` (string): Reference to parent chapter.
  - `languageCode` (string): `'en' | 'tl' | 'bik'`.
  - `title` (string): Localized chapter title.
  - `content` (string): Story paragraphs with bracketed `[vocabulary]` keywords.
  - `vocabularyHints` (array of objects):
    - `vocabularyId` (string): Stable content identity shared across translations of the same concept.
    - `word` (string)
    - `definition` (string)
    - `partOfSpeech` (string)
  - `needsReview` (boolean): Flag for translations needing expert validation.

---

### 5. `challenges` Collection
Reading comprehension question banks. A bank may have any positive number of
questions; a submitted attempt contains 1–5 unique question IDs selected from
that bank.

- **Document ID**: `challengeId` (e.g. `'chal_ibalong_ch1_en'`)
- **Fields**:
  - `chapterId` (string)
  - `languageCode` (string)
  - `version` (integer, defaults to 1 in readers)
  - `questions` (array of objects):
    - `id` (string)
    - `questionText` (string)
    - `choices` (array of strings)

---

### 6. `challengeKeys` (Private Collection)
Protected answer keys. **Clients have zero read/write access.**

- **Document ID**: `challengeId`
- **Fields**:
  - `answers` (map): Question ID to correct choice ID (for example, `{ "q1": "b" }`).

---

### 7. `progress` Subcollection
Canonical path: `/users/{uid}/progress/{storyId}`. There is no root progress collection.

- **Fields**:
  - `storyId` (string)
  - `completedChapterIds` (array of strings)
  - `updatedAt` (timestamp)
  - `projectionVersion` (integer; current version is `1`)

`storyCompleted` and `nextUnlockedChapter` are derived from completed IDs and
the canonical chapter order. They are never persisted in the progress
projection. Older documents without `projectionVersion` are read as version
zero and normalized on the next successful server projection write.

---

### 8. `attempts` Collection
Audit log of submitted quizzes and scoring results.

- **Document ID**: `attemptId` (UUID)
- **Fields**:
  - `userId` (string)
  - `storyId` (string)
  - `chapterId` (string)
  - `score` (number): 0 - 100
  - `correctAnswers` (number)
  - `totalQuestions` (number)
  - `xpAwarded` (number)
  - `passed` (boolean)
  - `attemptedAt` (timestamp)

See [PHASE3_FOUNDATION.md](./PHASE3_FOUNDATION.md) for the canonical
profile/progress contracts, ownership, approval lifecycle, question-bank
policy, idempotency, and vocabulary identity rules.
