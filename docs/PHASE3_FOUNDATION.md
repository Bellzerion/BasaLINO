# BasaLINO Phase 3 Foundation

Status: Phase 2.6 contracts are in place. This document describes the current
architecture and the constraints for future synchronization. It does not
authorize or implement a sync queue, worker, cloud progression write, or data
migration.

## Canonical profile contract

The profile document is `users/{uid}`. `uid` must match both the Firebase Auth
UID and the document ID.

| Field | Type | Contract |
|---|---|---|
| `uid` | string | Firebase Auth UID |
| `email` | string | Authenticated account email |
| `nickname` | string | Learner display name |
| `preferredLanguage` | string | One of `en`, `tl`, or `bik` |
| `approvalStatus` | string | One of `pending`, `approved`, or `rejected` |
| `totalXp` | integer | Current profile total; the Cloud Functions own cloud XP updates |
| `createdAt` | Firestore timestamp | Set by the profile bootstrap |

Profile bootstrap currently creates profiles with `approvalStatus: approved`
and `totalXp: 0`. Firestore rules validate this bootstrap shape, the profile
model validates the same fields, and progression Cloud Functions require an
approved profile. This is contract alignment, not a guardian-approval flow:
before guardian approval is a product requirement, profile approval must be
assigned by a trusted server path rather than self-approved by profile
bootstrap.

Profile updates are currently denied by Firestore rules. Future profile
preference events must not be used to change approval state or cloud XP.

## Canonical progress contract

The only canonical cloud story-progress path is:

```text
users/{uid}/progress/{storyId}
```

The existing Cloud Function writes `storyId`, `completedChapterIds`,
`currentUnlockedChapterId`, and `updatedAt`. Readers must not interpret a root
`progress/{uid}` collection as an alternate source. The client rules allow
owner reads and deny client writes. Attempts remain at `attempts/{attemptId}`
and are written by trusted backend logic.

The local `ProgressRepository` contract covers XP, attempts, chapter/story
completion, quiz snapshots, reading positions, vocabulary activities, and
vocabulary bonus records. The active local implementation persists story
progress, attempts, snapshots, reading positions, and vocabulary activity in
`basalino.progress.v1`; XP and one-time vocabulary bonus chapter IDs retain
their existing per-user SharedPreferences keys. Legacy progress documents
remain readable; Phase 2.6 does not migrate stored progress.

`isStoryCompleted` is represented locally and accepted by the progress model.
The current quiz Cloud Function does not write that field. Cloud story
completion should be derived from authoritative chapter metadata or added to
the server contract in a separately reviewed backend change; clients must not
claim an authoritative cloud completion based solely on local state.

## Progression ownership

`AuthRepository` owns identity operations only: sign-in, registration,
sign-out, and auth-state observation. It does not award XP or mutate learner
progress.

`ProgressMutationService` is the application-facing owner for progression
mutations. It coordinates XP awards, vocabulary bonuses, attempt submission
records, chapter/story completion, reading-position changes, and vocabulary
activity through the `ProgressRepository` abstraction. Screens depend on the
service and repository interfaces, not on `LocalProgressRepository`.

The Firebase story-progress repository reads cloud progress but delegates
mutation methods to local persistence. This is a compatibility seam, not a
cloud write or a sync implementation.

## Sync event contract (design only)

The immutable `SyncEvent` envelope contains:

```json
{
  "eventId": "stable-operation-id",
  "userId": "authenticated-user-id",
  "deviceId": "stable-installation-id",
  "type": "quiz_attempt_submitted",
  "aggregateId": "story-or-profile-id",
  "occurredAt": "UTC ISO-8601 timestamp",
  "schemaVersion": 1,
  "payload": {}
}
```

Supported event types are `quiz_attempt_submitted`,
`vocabulary_activity_recorded`, `reading_position_set`, and
`profile_preference_changed`. `eventId` is the future idempotency key and
must remain stable when retrying the same operation. `userId` must be checked
against the authenticated UID by any future receiver. Payloads are immutable
JSON-compatible values. The model performs no enqueueing, persistence, upload,
or replay.

## Vocabulary identity

Every bundled vocabulary hint has a `vocabularyId` that is shared across
translations of the same chapter concept. Vocabulary activity records carry
that ID in addition to the display word and language code. Mastery aggregation
should key by `vocabularyId`, not by a translated word. IDs are content
identifiers and must remain stable when translations or definitions are
edited. Legacy hints without an ID receive a compatibility identifier and
must be assigned a canonical ID before they participate in cross-language
mastery.

## Future synchronization assumptions

- Local repositories remain the active data source in local mode.
- Preserve local write-first behavior for reading position and vocabulary
  activity; do not silently fall back to another identity when cloud access
  fails.
- Quiz grading, accepted chapter completion, unlocks, and authoritative XP
  remain server-owned for Firebase accounts.
- Use stable operation IDs and server-side idempotency before retryable writes
  are enabled.
- Merge vocabulary activity by `vocabularyId` and deduplicated operation ID;
  merge reading positions with a documented deterministic rule.
- Do not merge XP totals by summing device snapshots.
- Any profile-preference updates require an explicit allowed-field policy;
  approval and XP remain server-controlled.
- Queue storage, retry policy, retention, conflict resolution, migrations,
  and sync-worker behavior are intentionally undecided for implementation and
  must be reviewed before Phase 3.

## Phase 3 entry gate

Before enabling sync, validate the profile and progress contracts against
Firestore rules and Cloud Functions, define authoritative story-completion
semantics, assign stable device IDs, design durable idempotency, and test
local-data preservation across sign-in, offline, retry, and multi-device
scenarios. No cloud progression writes are enabled by Phase 2.6.
