# BasaLINO Cloud Firestore Data Model

This document outlines the Firestore collections and document schema for BasaLINO.

---

### 1. `users` Collection
Stores learner profile, role, approval state, and total accumulated XP.

- **Document ID**: `uid` (Firebase Auth UID)
- **Fields**:
  - `email` (string): Registered email address.
  - `nickname` (string): In-app display name.
  - `preferredLanguage` (string): `'en' | 'tl' | 'bik'`.
  - `approvalStatus` (string): `'pending' | 'approved' | 'rejected'` (Default: `pending` or `approved` based on guardian flow).
  - `totalXp` (number): Authoritative total XP awarded exclusively by backend logic.
  - `createdAt` (timestamp): Account creation timestamp.

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
    - `word` (string)
    - `definition` (string)
    - `partOfSpeech` (string)
  - `needsReview` (boolean): Flag for translations needing expert validation.

---

### 5. `challenges` Collection
Reading comprehension questions and choices.

- **Document ID**: `challengeId` (e.g. `'chal_ibalong_ch1_en'`)
- **Fields**:
  - `chapterId` (string)
  - `languageCode` (string)
  - `questions` (array of objects):
    - `id` (string)
    - `questionText` (string)
    - `choices` (array of strings)

---

### 6. `challengeKeys` (Private Collection)
Protected answer keys. **Clients have zero read/write access.**

- **Document ID**: `challengeId`
- **Fields**:
  - `answers` (map): Key-value pair of question ID to correct answer text: `{ "q1": "Baltog", "q2": "Tandayag the wild boar" }`

---

### 7. `progress` Collection
Subcollection under user or root: `/users/{userId}/progress/{storyId}`

- **Fields**:
  - `storyId` (string)
  - `completedChapterIds` (array of strings)
  - `currentUnlockedChapterId` (string)
  - `updatedAt` (timestamp)

---

### 8. `attempts` Collection
Audit log of submitted quizzes and scoring results.

- **Document ID**: `attemptId` (UUID)
- **Fields**:
  - `userId` (string)
  - `chapterId` (string)
  - `score` (number): 0 - 100
  - `correctAnswers` (number)
  - `totalQuestions` (number)
  - `xpAwarded` (number)
  - `passed` (boolean)
  - `attemptedAt` (timestamp)
