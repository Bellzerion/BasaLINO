# BasaLINO Phase 3 Foundation

Status: Phase 2.7 cloud contracts. This document is authoritative for cloud
profile, progression projection, challenge-bank, and vocabulary identity
contracts. It does not authorize or implement synchronization, a queue, an
outbox, a worker, or local-to-cloud progress migration.

## Canonical profile

The profile is the `users/{uid}` document. `uid` equals the Firebase Auth UID
and document ID.

| Field | Type | Requirement and meaning | Owner |
|---|---|---|---|
| `uid` | string | Required; authenticated UID | Firebase Auth / server validation |
| `email` | string | Required; must match the authenticated email on bootstrap | Firebase Auth |
| `createdAt` | Firestore timestamp | Required; set with server timestamp | Server |
| `approvalStatus` | string | Required; `pending`, `approved`, or `rejected` | Trusted server/admin |
| `preferredLanguage` | string | Required; `en`, `tl`, or `bik` | User; bootstrap initializes `en` |
| `displayName` | string | Optional display name, max 80 characters | Firebase Auth; optional profile snapshot |
| `totalXp` | non-negative integer | Server-maintained projection; absent until the first server XP award | Cloud Functions |

`totalXp` is not accepted on client profile creation or update. Cloud
Functions may create/update it using the server-side XP award transaction.
No other profile fields are part of the current contract.

For read compatibility only, the profile model and Cloud Functions recognize
the old Phase 2.6 `nickname` field when `displayName` is absent. New profile
writers and Firestore rules do not accept or write `nickname`. This adapter is
temporary; existing documents should be normalized by a reviewed admin
operation before it is removed.

### Approval lifecycle

Client bootstrap creates a profile with `approvalStatus: pending`. Firestore
rules require pending status at creation and deny client profile updates.
Only a trusted admin/server process may transition status to `approved` or
`rejected`. `submitAttempt` and `awardVocabularyBonus` validate the complete
profile contract and require `approved`.

There is not yet a guardian-consent workflow. Existing Phase 2.6 profiles may
contain `approved` from the old client-writable bootstrap; audit those legacy
approvals before treating them as guardian-approved. The compatibility reader
does not convert or promote approval status.

Firebase auth state hydrates approval and preferred language from this profile
contract; it must not infer approval from successful Firebase authentication.

## Canonical progress storage and projection

The only cloud story-progress path is:

```text
users/{uid}/progress/{storyId}
```

Client rules allow only owner reads and deny client writes. Trusted
`submitAttempt` writes the projection. Root `progress/{uid}` is not a valid
path. Quiz attempt records remain at `attempts/{attemptId}`. Vocabulary bonus
deduplication records remain at
`users/{uid}/vocabularyBonuses/{chapterId}`.

The authoritative story-progress document contains exactly:

| Field | Type | Meaning |
|---|---|---|
| `storyId` | string | Must match the document ID |
| `completedChapterIds` | string array | Chapters accepted by the server |
| `updatedAt` | Firestore timestamp | Server write time |
| `projectionVersion` | integer | Current projection schema version, `1` |

`storyCompleted` and `nextUnlockedChapter` are derived, not persisted.
Derivation uses the canonical `chapters` collection (`storyId` and unique
`orderIndex`): sort chapters by `orderIndex`, find the first chapter not in
`completedChapterIds` as `nextUnlockedChapter`, and consider the story complete
only when every known chapter is completed. Returned attempt results expose
these derived values; the cloud reader derives the in-memory local-compatible
model the same way.

Documents written before projection version 1 may omit `projectionVersion`
and contain the old `currentUnlockedChapterId`. Readers treat those as
projection version 0, ignore the persisted derived field, and derive current
values from chapter metadata. The next successful server projection write
normalizes that story document to version 1. No progress migration runs here.

`CloudProgress` derives completed story counts from chapter metadata and
completed IDs. Vocabulary activity is not in this projection and cloud
vocabulary counts remain zero until a separately approved cloud activity
contract exists.

## Question-bank contract

Policy: **variable-length banks and attempts**. A bank must contain at least
one question, unique non-empty question IDs, non-empty choice lists, and one
valid answer key per question. A submitted attempt selects between 1 and 5
distinct IDs that exist in the requested bank; the answers map must contain
exactly those IDs. Banks may contain more than five questions; the client
selects at most five, using repeat avoidance where possible. Banks with fewer
than five questions are submitted at their actual length.

The same contract is enforced by:

- `ChallengeModel` and local/Firebase challenge repositories
- the Cloud Function, which checks bank/chapter/story relationships and answer
  IDs against the private answer key
- seed validation, which checks bank metadata, IDs, choices, and answer-key
  coverage before writing
- emulator integration tests

Scoring remains server authoritative: 60% passes; awarded XP remains 10 per
correct answer plus 5 for a perfect score. The bank size does not change the
formula.

## Transaction and idempotency contract

`attemptId` is the stable document ID at `attempts/{attemptId}`. The function
reads the attempt document inside the same Firestore transaction that reads
the profile/progression and creates the attempt, increments XP, and updates
the projection. Firestore transaction retries serialize concurrent requests.
If the ID already belongs to this user, the function returns the stored result
with zero additional XP; if it belongs to another user, the request is denied.

Vocabulary bonus identity is the chapter-specific document
`users/{uid}/vocabularyBonuses/{chapterId}`. The function checks/creates this
document and increments profile XP in one transaction. Replays return no
additional award.

Profile approval, challenge bank, answer key, chapter metadata, current
projection, attempt ID, and XP effects are validated/checked before any
transaction writes. Admin SDK writes bypass Firestore client rules; tests
therefore cover both rules and Functions Emulator behavior.

## Vocabulary identity

Bundled vocabulary hints carry stable `vocabularyId` values shared across
translations of the same concept. Vocabulary activity records carry that ID
alongside the localized word and language. Future mastery must key by
`vocabularyId`, not translated text. IDs are stable content identifiers and
must not change when a translation or definition is edited. This phase adds
no mastery aggregation or cloud vocabulary write.

## Cloud field ownership

| Cloud field/data | Owner |
|---|---|
| Profile `uid`, `email` | Firebase Auth identity, verified by server/rules |
| Profile `createdAt` | Server timestamp |
| Profile `approvalStatus` | Trusted admin/server only |
| Profile `preferredLanguage` | User preference; client bootstrap only for now |
| Profile `displayName` | Firebase Auth; optional profile snapshot |
| Profile `totalXp` | Cloud Function transaction |
| Progress `storyId`, `completedChapterIds`, `updatedAt`, `projectionVersion` | Cloud Function projection |
| `storyCompleted`, `nextUnlockedChapter` | Derived by readers/functions from canonical chapter metadata; never stored |
| Attempt score, pass, XP, and timestamp | Cloud Function |
| Vocabulary bonus record and XP | Cloud Function transaction |
| Challenge bank and translations | Content/seed process |
| Challenge answer keys | Content/seed process; server-only reads |
| Legacy `nickname` | Existing Phase 2.6 data only; read-compatible, no new writer |

## Phase 3 prerequisites

- Audit/reset legacy approval statuses that were client-created as approved;
  implement the actual guardian-consent lifecycle.
- Normalize legacy profile `nickname` documents to optional `displayName`.
- Define server-generated chapter IDs/order metadata and ensure every story
  has unique contiguous-or-documented `orderIndex` values.
- Keep server transactions and idempotency IDs authoritative when any future
  offline operation replay is introduced.
- Design a separate vocabulary-activity cloud contract before syncing mastery.
- Define preference update rules, stable device identity, queue retention,
  failure handling, and cross-device conflict behavior.
- Validate the current contracts on the emulators and supported platforms
  before enabling any Phase 3 writes.

No synchronization queue, outbox, worker, retry system, connectivity monitor,
local progress migration, or gameplay cloud-write path is implemented by
Phase 2.7.
