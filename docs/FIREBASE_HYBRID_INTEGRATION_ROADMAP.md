# BasaLINO Firebase Hybrid Integration Roadmap

Status: roadmap. Phase 2.6 repository/profile/progress foundations are now
implemented; sync queues, workers, and cloud progression writes remain
unimplemented.

## Executive assessment

BasaLINO has useful Firebase foundations, but is not ready to switch
authentication or progress persistence to Firebase as-is.

| Area | Current state | Readiness |
|---|---|---|
| Local mode | Local auth, story, challenge, and progress repositories are selected by Riverpod providers. | Working baseline to preserve |
| Firebase dependencies | Firebase Auth, Firestore, Functions, and Core packages are declared. | Available |
| Firebase initialization | Firebase initialization is configured for the current app. | Implemented |
| Firebase repository wiring | Local repositories remain active; Firebase progress reads are available behind repositories. | Partial |
| Firebase Auth/profile | Firebase auth uses `users/{uid}` and the canonical profile contract; profile bootstrap writes `approvalStatus: approved`. | Read contract aligned |
| Secure quiz progression | `submitAttempt` Cloud Function grades answers and writes attempt, XP, and chapter progress. | Strong starting point; hardening needed |
| Progress repository | A shared mutation contract and ProgressMutationService exist; Firebase story mutations still delegate to local persistence. | Sync not implemented |
| Offline support | Local progress persists in SharedPreferences. Firestore rules disallow client progress writes. | Local mode only |
| Reading/vocabulary sync | Reading positions and vocabulary activity are local-repository-specific. | Missing |
| Security rules and schema | Owner-scoped reads and server-only progression writes are defined. | Useful baseline; test with emulators |
| Emulator setup | Auth, Firestore, and Functions emulator ports are configured. | Configured, app connection/setup incomplete |

## Current architecture findings

### Repository and identity boundaries

- `providers.dart` currently constructs `LocalAuthRepository`,
  `LocalStoryRepository`, `LocalChallengeRepository`, and
  `LocalProgressRepository`. The Firebase repositories are not active.
- `FirebaseAuthRepository` authenticates with Firebase Auth and uses the
  Firebase UID as the profile document ID.
- The local account index and local progress/XP are separate from Firebase.
  Local learner IDs must not be assumed to equal future Firebase UIDs.
- Firebase initialization is available, while local mode remains the active
  repository configuration and must remain usable without cloud availability.
- Local mock sign-in is not real credential verification. Its email-to-UID
  record is a local identity convenience, not proof that the email is owned
  by its user.

### Persistence and write paths

- Local progress is stored under the SharedPreferences key
  `basalino.progress.v1`, with per-user data under the JSON `users` map.
  It includes chapter progress, quiz attempts/snapshots, reading positions,
  and vocabulary activity.
- Local XP and one-time vocabulary bonus records use
  `basalino.user.xp.v1.<uid>` and
  `basalino.vocabularyBonus.v1.<uid>`.
- Firebase progress currently supports reads from
  `users/{uid}/progress/{storyId}` and root `attempts`, but does not implement
  writes or offline reconciliation.
- Quiz and vocabulary screens now call `ProgressMutationService`; concrete
  local repository checks have been removed from UI code.
- `AuthRepository` is authentication-only. Local XP retains its existing
  SharedPreferences keys, and cloud XP remains owned by trusted backend logic.
- Reader position and vocabulary activity are available through the
  `ProgressRepository` contract; cloud synchronization is not implemented.
- Firestore rules deny direct client writes to progression and attempts.
  Any sync design must respect this and use trusted Cloud Functions for
  authoritative progression and XP.
- The source-of-truth contracts are documented in
  [PHASE3_FOUNDATION.md](./PHASE3_FOUNDATION.md); it supersedes stale
  pre-Phase-2.6 repository/schema statements in this roadmap.

### Backend foundations and gaps

- `submitAttempt` validates answers server-side and transactionally updates
  `users/{uid}.totalXp`, `users/{uid}/progress/{storyId}`, and
  `attempts/{attemptId}`.
- `awardVocabularyBonus` uses a per-user bonus record and a transaction to
  prevent repeat XP awards.
- The `submitAttempt` duplicate-attempt lookup occurs before its transaction.
  Concurrent requests with the same attempt ID should be made race-safe by
  checking/creating the idempotency record within the transaction.
- Chapter unlock mapping is hard-coded in the function. Before expanding
  content, use canonical chapter metadata or a validated progression service
  so new stories do not require fragile client/server ID assumptions.
- Current Firestore rules and indexes cover existing user/progress/attempt
  reads, but no emulator-based rules or function integration test suite was
  found during this assessment.

## Target hybrid behavior

1. **Local mode remains available.** Local-only users continue using the
   current local repositories and existing SharedPreferences schema.
2. **Firebase identity is authoritative for signed-in cloud users.** Use
   Firebase Auth UID for all cloud paths. Never derive cloud identity from
   email or `hashCode`.
3. **Local data is the durable offline cache/outbox.** Preserve local data
   while signed in and offline; queue eligible events and sync after
   connectivity/auth are available.
4. **Server owns grades, unlocks, and XP.** A locally queued quiz is pending,
   not a passed chapter. Only server-accepted attempts can grant XP or
   authoritative completion/unlock state.
5. **No silent mode fallback.** A Firebase outage must not silently switch a
   Firebase account into a new local identity. Show/record the offline state,
   preserve local work, and retry sync.

## Proposed Firestore schema

Keep the existing user and progression paths as the compatibility baseline:

```text
users/{firebaseUid}
  email
  nickname
  preferredLanguage
  approvalStatus
  totalXp                  # server-authoritative
  createdAt

users/{firebaseUid}/progress/{storyId}
  storyId
  completedChapterIds
  currentUnlockedChapterId
  updatedAt

attempts/{operationId}
  userId
  storyId
  chapterId
  challengeId
  questionIds
  score
  totalQuestions
  correctAnswers
  xpAwarded
  passed
  nextChapterId
  attemptedAt

users/{firebaseUid}/vocabularyBonuses/{chapterId}
  chapterId
  xpAwarded
  awardedAt

users/{firebaseUid}/vocabularyActivity/{activityId}
  chapterId
  languageCode
  word
  activityType
  correct
  completedAt
  operationId

users/{firebaseUid}/readingPositions/{chapterId}
  storyId
  chapterId
  position
  updatedAt
  clientMutationId
```

Vocabulary activity and reading positions are proposed additions, not current
collections. Keep durable content collections (`stories`, `chapters`,
`chapterTranslations`, `challenges`, and protected `challengeKeys`) separate
from learner-owned data. Preserve existing rules that prevent client writes
to scores, XP, progress, and attempts; add narrowly scoped rules or callable
functions for any new data.

The local outbox should remain on-device and keyed by Firebase UID once an
account is linked. Store operation IDs and sync status separately from the
existing `basalino.progress.v1` schema until a versioned migration is
designed.

## Synchronization and conflict rules

| Data | Authority | Offline behavior | Merge rule |
|---|---|---|---|
| Quiz submission/result | Cloud Function | Persist a pending submission; do not show it as graded or award XP until server response. | Immutable attempt keyed by idempotency ID; server result wins. |
| Completed chapters | Server-accepted pass | Keep last confirmed status visible offline; pending quizzes are clearly unconfirmed. | Union only server-validated passes. Recompute unlocked chapter from canonical chapter order/rules rather than taking an arbitrary last write. |
| XP | Server profile / server transaction | Show last confirmed total; avoid adding provisional XP to the authoritative total. | Server transaction plus idempotent award ID; never merge by summing client totals. |
| Vocabulary activity | Local append-only event, then cloud copy | Record locally and enqueue sync. | Immutable records keyed by operation ID; aggregate distinct words from deduplicated records. Bonus XP remains a separate server-authoritative award. |
| Reading position | Local cache, then cloud | Save locally immediately and enqueue latest position. | Per-user/per-chapter last-write-wins using server timestamp and mutation ID; accept that competing devices may choose the latest acknowledged write. |
| Profile/language | Firebase profile | Cache last known value; queue permitted profile edits if desired. | Explicit field-level updates; clients cannot change approval state or XP. |

Requirements for the outbox:

- Stable random operation ID created once and reused on every retry.
- Per-user queue; never sync one user's queue under another user's Firebase UID.
- Persist operation type, payload, creation time, attempt count, and sync state.
- Retry transient network failures with bounded backoff; surface permanent
  auth/rules/validation failures for recovery rather than dropping records.
- Sync after authentication, connectivity restoration, and app resume.
- Make server mutations idempotent and safe under concurrent retries.
- Keep successful records/history until a documented retention policy allows
  pruning.

Firestore mobile persistence may help cache reads, but it does not replace
SharedPreferences/local outbox storage, especially where rules intentionally
deny direct progression writes. Verify persistence behavior separately on
Android, iOS, desktop, and web; web offline cache has platform-specific
configuration and browser storage considerations.

## Local-to-Firebase account and data migration

### Recommended migration sequence

1. Back up `basalino.localAccounts.v1`, `basalino.progress.v1`, all
   `basalino.user.xp.v1.*` entries, and all
   `basalino.vocabularyBonus.v1.*` entries before migration.
2. Require a successful Firebase Auth sign-in or verified account creation
   before associating local progress with a cloud UID. Do not trust a typed
   email alone; local mock auth does not verify email ownership.
3. Find the local account index entry by normalized email and read its old
   local UID. Keep that mapping and the original local payload unchanged.
4. Upload a migration manifest to a trusted migration callable with source
   local UID, target Firebase UID, schema version, and stable migration ID.
   The server validates ownership, IDs, size/shape, and replay protection.
5. Merge only eligible data. For existing quiz records, use server-validated
   attempt evidence where available. Do not accept client-supplied scores or
   XP as authoritative. Regrade stored quiz answers only if the historical
   snapshot contains enough information and the same grading rules can be
   verified.
6. Preserve unreconciled local records as local history and report which
   entries could not be promoted to authoritative cloud progress.
7. Verify counts, completion state, XP, reading position, vocabulary history,
   and idempotent retry behavior before marking migration complete.
8. Retain the local backup and rollback path for a defined support period.

### Legacy data and risks

- Data created before `basalino.localAccounts.v1` may have a registration UUID
  without a recoverable email-to-UID mapping. Do not guess its owner. Recovery
  requires a trusted backup, user-assisted support process, or another
  verifiable association.
- Existing local pass records and XP are client-controlled and may not prove
  a legitimate server-graded result. Automatically importing them as
  authoritative could enable forged completions or XP. Preserve them, but
  quarantine/unverify unsupported claims unless product policy approves a
  clearly labeled legacy import.
- Two devices may have separate local histories for one Firebase account.
  Their append-only events can be merged, but stale reading positions and
  repeated vocabulary records need operation IDs and deterministic rules.
- Never overwrite a non-empty cloud profile/progress document with local
  defaults during sign-in or migration.
- Keep local-only learner records private to the device/account context;
  switching users must never expose another user's local cache.

## Phased implementation roadmap

### Phase 0 — Configuration and safety baseline

- Add explicit Local, Firebase, and emulator environment selection.
- Configure Firebase per supported platform and initialize only when the
  selected mode requires it.
- Keep local mode launchable without Firebase configuration or credentials.
- Add emulator startup instructions and automated rules/function tests.
- Capture baseline behavior for local account identity, local progress,
  chapter unlocks, XP, reading position, and vocabulary.

**Exit gate:** Local app and tests continue working with Firebase unavailable;
emulator configuration can be used without production credentials.

### Phase 1 — Firebase Authentication behind providers

- Add Firebase initialization/options and emulator connection.
- Select `FirebaseAuthRepository` only in Firebase mode; retain
  `LocalAuthRepository` in Local mode.
- Make auth state loading, signed-out, authenticated, approval-pending, and
  network/error states explicit.
- Ensure profile bootstrap is idempotent and missing profile documents are
  handled as recoverable provisioning errors, not null assertions.
- Test repeated signup/sign-in/sign-out with stable Firebase UID and profile.

**Exit gate:** Firebase auth users consistently map to one `users/{uid}`
profile; Local mode behavior and local account data are unchanged.

### Phase 2 — Repository contracts and cloud reads

- Replace `is LocalProgressRepository` UI branching with repository interfaces
  for quiz snapshots, attempt recording, reading position, and vocabulary
  activity.
- Make repository providers depend on a single selected mode/auth identity.
- Add Firebase-backed progress/profile reads and refresh/invalidation after
  Cloud Function mutations.
- Add safe offline cache behavior with explicit stale/loading/error states.

**Exit gate:** Local and Firebase implementations satisfy the same behavioral
contract; reads never cross learner UIDs.

### Phase 3 — Authenticated hybrid local cache and outbox

- Preserve local write-first behavior for reading position and vocabulary
  activity.
- Add versioned outbox and per-operation idempotency metadata without
  destructively changing current local data.
- For Firebase-authenticated users, partition cached data and pending events
  by Firebase UID.
- Do not locally authorize quiz passes, chapter unlocks, or XP.
- Add retry, connectivity/app-resume triggers, diagnostics, and manual
  recovery for permanently rejected events.

**Exit gate:** Offline reading/vocabulary survives restart and syncs once
online; unsent quiz submissions remain visibly pending and never grant XP.

### Phase 4 — Secure progression and server idempotency

- Keep grading, pass decisions, progression, and XP in trusted Cloud
  Functions.
- Move attempt idempotency checks inside the transaction and reject an
  operation ID already owned by another user.
- Validate the requested story/chapter/challenge relationship against
  canonical server data.
- Replace hard-coded chapter unlock mapping with validated progression rules.
- Return enough authoritative state for the client to refresh its profile and
  progress views.
- Add emulator tests for duplicate and concurrent submissions, owner checks,
  approval checks, retry after timeout, and exactly-once XP.

**Exit gate:** Repeating any submission cannot duplicate attempts, completion,
unlock, or XP.

### Phase 5 — Local account migration pilot

- Implement the migration callable/manifest, preview, confirmation, and
  result reporting.
- Pilot with test accounts representing mapped accounts, ambiguous legacy
  UIDs, conflicting local/cloud progress, and multiple devices.
- Do not auto-link by email unless Firebase Auth has verified the account.
- Keep original local keys intact and support rollback/export.

**Exit gate:** Migration is idempotent, auditable, non-destructive, and passes
the data-preservation and security acceptance suite.

### Phase 6 — Gradual rollout and retirement decision

- Enable Firebase mode for internal/test cohorts behind a remote or build
  flag; keep Local mode available.
- Monitor auth failures, sync queue age/failures, duplicate operation
  rejection, data reconciliation, and XP discrepancies.
- Expand cohorts only after data parity and support procedures are proven.
- Retire or deprecate local account auth only after an explicit product
  decision; retain offline progress/cache behavior.

## Acceptance criteria

- Local mode works without Firebase initialization and all existing local
  account/progress tests remain green.
- Firebase UID remains stable across app restart and same-account login.
- Two Firebase users cannot read, write, or sync each other's records.
- Server-confirmed chapter completion and XP survive logout/login and
  reinstall/cache rebuild.
- Offline reading position and vocabulary activity survive app restart and
  eventually sync once without duplicate records.
- Offline quiz attempts do not show a confirmed pass or award XP before
  server grading.
- Duplicate/retried quiz and bonus requests award XP at most once.
- Migration never deletes or overwrites local source data; ambiguous ownership
  is reported, not guessed.
- Firestore rules and callable authorization are tested with Firebase
  emulators before production rollout.
