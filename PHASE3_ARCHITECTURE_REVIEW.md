# BasaLINO Phase 3.5 — Hybrid Sync Architecture Review

**Review date:** 2026-11-10  
**Scope:** Design assessment only. No sync, queue, Firestore-write, repository, or gameplay changes are included.

## Executive Summary

BasaLINO has a useful offline foundation and a promising trusted-server foundation, but the current application is **not ready to enable multi-device synchronization**.

The active runtime uses Firebase Authentication but local story, challenge, and progress repositories. XP, vocabulary bonuses, quiz attempts, chapter completion, reading position, and vocabulary activity are persisted locally. Firebase profile/progress reads are disabled by the current `DataMode.local` setting. Firestore rules deny client writes to progression, while existing Cloud Functions provide a separate server-authoritative attempt and XP path that is not selected by the active providers.

The main design decision is to use **local-first capture with server-authoritative acceptance**:

- Persist learner actions locally so reading and practice remain available offline.
- Treat offline quiz submissions as pending, not graded; do not grant authoritative XP or unlock chapters until a trusted server accepts the attempt.
- Synchronize immutable, uniquely identified events/commands; build read-optimized progress and XP totals as server-maintained projections.
- Keep Cloud Functions as the authority for quiz grades, XP awards, and chapter unlocks.

**Readiness decision: NO-GO for turning on Phase 3 sync today.** Proceed with Phase 3 design and prerequisite work only after the blockers in this report are resolved and tested. This is not a recommendation to stop the project; it is a gate against enabling a partially connected sync path that could lose or duplicate learner progress.

## Review Basis

This review examined the selected Riverpod providers and auth/data modes; local and Firebase repository implementations; progress, user, and challenge models; quiz, vocabulary, reader, and progress-screen call sites; Firestore rules; Cloud Functions; seed data; and existing Firebase/data-model/quiz design documents. See the [provider wiring](lib/app/bootstrap/providers.dart), [auth/data mode](lib/core/config/auth_mode.dart), [local progress repository](lib/core/services/local_progress_repository.dart), [Firestore rules](firestore.rules), [Cloud Functions](functions/src/index.ts), and [cloud data model](docs/DATA_MODEL.md).

## Decision Matrix

| Review area | Current evidence | Phase 3 assessment | Recommendation |
|---|---|---|---|
| Offline progress | Local progress and XP use SharedPreferences; progress survives repository restart in tests. | Good single-device baseline; no cloud reconciliation or durable multi-operation transaction. | Keep local-first capture; add a transactional local store/outbox before enabling sync. |
| Sync queues | No outbox or sync lifecycle exists. | Not ready. | Use a per-Firebase-UID SQLite outbox with stable operation IDs and explicit acknowledgements. |
| Event-based sync | Local attempts and vocabulary records have IDs; no common event contract exists. | Partial raw material, not a replayable event model. | Synchronize immutable learner actions; have trusted server handlers validate and project authoritative state. |
| Multi-device usage | Gameplay state is local to one device; Firebase UID and local data are not reconciled. | Not supported. | Bind all local records to an authenticated Firebase UID and define an explicit legacy-data migration. |
| Conflict resolution | Cloud progress stores a chapter-ID array and one current-unlock scalar; no general version or merge protocol. | Incomplete; scalar unlock state can regress. | Merge validated completion facts monotonically and derive unlocks from canonical chapter order. |
| Future Cloud Functions | `submitAttempt` and `awardVocabularyBonus` exist; server transactions and Firestore rules provide a foundation. | Promising but inconsistent with current profile creation, payload sizes, and runtime wiring. | Resolve the listed server/schema blockers and add emulator tests before routing production calls. |
| Repository boundaries | Interfaces exist, but key mutation methods are concrete-only and XP is owned by AuthRepository. | Partial; active UI is coupled to a local repository implementation. | Define domain-level mutation contracts and keep Firebase/local adapters behind providers. |

## 1. Current Data Ownership

| Data type | Current storage | Current repository / owner | Sync risk |
|---|---|---|---|
| Quiz XP | `SharedPreferences` key `basalino.user.xp.v1.<uid>`; total incremented by the auth repository. `LocalChallengeRepository` calculates quiz XP; `ChallengeScreen` applies it through `AuthRepository.addXp`. | `AuthRepository` currently owns the total, while challenge grading determines the award. | **High — split ownership and non-atomic updates.** XP total has no durable award ledger in the active path. Replaying a quiz or retrying after partial persistence can produce a different total than the attempt history. |
| Vocabulary-bonus XP | `SharedPreferences` total XP plus `basalino.vocabularyBonus.v1.<uid>` chapter-ID list. | `AuthRepository.awardVocabularyBonus`; the vocabulary screen invokes it after a passed quiz. | **High — idempotency is device-local.** Two devices have independent “already awarded” lists and can each award the bonus. The Firebase implementation saves the bonus marker and XP in separate local writes. |
| Quiz attempt history | `basalino.progress.v1`, nested under per-user `attempts`; saved as a single JSON document. | `LocalProgressRepository.recordAttemptAndUnlock`. | **High — local only and not atomic with XP.** The attempt ID is separate from the quiz snapshot ID. There is no common server idempotency key in the active local path. |
| Story completion | Not stored as a separate fact. The completion screen derives it when every chapter is completed. | Derived from `ProgressRepository` chapter status and story metadata. | **Medium — derived state can disagree across devices** if one device has incomplete or stale chapter records. |
| Chapter completion | `completedChapterIds` in a `StoryProgressModel` persisted in the progress JSON. Recorded when a quiz is passed. | `LocalProgressRepository.recordAttemptAndUnlock`; Firebase Function has a separate cloud writer. | **High — local/client-accepted pass is not equivalent to a server-validated pass.** Need pending vs accepted states. |
| Unlocked chapter | Single `currentUnlockedChapterId` stored with story progress; first chapter is inferred when no record exists. | `LocalProgressRepository`; unlock status is computed by `getChaptersWithStatus`. | **High — a last-written scalar is unsafe under out-of-order multi-device updates.** Derive from server-validated completion facts instead. |
| Vocabulary activity | `vocabularyRecords` in the local progress JSON; each record includes a generated ID, chapter, language, word, activity, correctness, and timestamp. Only the newest 100 are serialized. | `LocalProgressRepository.recordVocabularyActivity`, called by the vocabulary practice screen. | **High — bounded event history drops older records; no stable vocabulary concept ID or mastery model exists.** Duplicate attempts and distinct-language forms are not normalized. |
| Vocabulary mastery | No mastery state exists. The app counts distinct `(languageCode, word)` pairs among retained records. | Derived by `LocalProgressRepository.getVocabularyWordsPracticedCount`. | **High — “practiced” is not mastery; truncation changes counts and future mastery cannot be reconstructed reliably.** |
| Reading position | `readingPositions` in the local progress JSON, keyed by user/story/chapter, written after a debounce. | Local-only methods on `LocalProgressRepository`, called by `ReaderScreen`. | **Medium — single last-write value; competing devices need per-chapter reconciliation.** |
| Quiz snapshots | At most 20 snapshots per learner are persisted, with IDs, bank version, question IDs, answers, and timestamps. | Concrete-only methods on `LocalProgressRepository`. | **Medium — snapshot ID is not the active server attempt ID; bounded retention and missing linkage complicate safe retry and migration.** |
| Profile and preferences | Firebase Auth supplies identity/display name. `FirebaseAuthRepository` keeps language overrides in memory and XP in local preferences. A cloud profile created by `FirebaseProfileRepository` currently contains only UID, email, and creation time. | `AuthRepository`/Firebase Auth plus `FirebaseProfileRepository` for an optional cloud read path. | **High — profile fields have multiple or incomplete owners; language is not durable in this implementation, and profile schema disagrees with function expectations.** |

Local progress format and the bounded quiz/vocabulary records are visible in [LocalProgressRepository](lib/core/services/local_progress_repository.dart); XP and vocabulary bonuses are in [FirebaseAuthRepository](lib/core/services/firebase_auth_repository.dart); quiz orchestration is in [ChallengeScreen](lib/features/challenges/presentation/challenge_screen.dart); vocabulary recording is in [VocabularyPracticeScreen](lib/features/vocabulary/presentation/vocabulary_practice_screen.dart).

## 2. Repository Boundary Audit

| Repository | Intended ownership | Current assessment |
|---|---|---|
| `AuthRepository` | Authentication lifecycle and identity. | **Responsibility leak:** also owns `addXp`, vocabulary bonus idempotency, and the bonus-XP constant. Those are learner progression/reward operations, not authentication. `UserModel.totalXp` also couples profile state to progression. |
| `ProgressRepository` | Learner progress queries and mutations. | **Incomplete abstraction:** the interface exposes reads only. Quiz snapshots, attempt recording, reading position, vocabulary activities, and vocabulary counts are methods only on `LocalProgressRepository`. UI code type-checks/casts to that concrete class, so another implementation cannot transparently replace it. |
| `StoryRepository` | Read story, chapter, and translation content. | **Mostly clear:** it serves content independently. `ProgressRepository.getChaptersWithStatus` takes on status composition and depends on a `StoryRepository`, which is a small cross-domain/application-service coupling to consider when mutation contracts are designed. |
| `ChallengeRepository` | Challenge retrieval and attempt submission. | **Mostly coherent domain, inconsistent adapters:** the local implementation selects and grades questions and returns an XP/unlock result; the Firebase implementation calls the server. `ChallengeScreen` additionally persists progress and awards XP itself, so submission side effects are split across repository, UI, and auth repository. |

**Boundary violations to resolve before sync:**

1. Move reward/progression ownership out of `AuthRepository`; authentication should not own XP totals or bonus idempotency.
2. Put the required learner mutations behind explicit interfaces instead of `is LocalProgressRepository` checks and concrete-only methods in screens.
3. Give attempt submission one clear owner for validation and authoritative results. The UI can coordinate a use case, but should not independently award authoritative XP.
4. Define profile ownership separately from progress and make each profile field’s authority explicit.
5. Ensure local and cloud implementations satisfy the same behavioral contract, including offline/pending outcomes and durable operation IDs.

## 3. Firestore Shape and Readiness

### Current paths and behavior

- The documented story progress path is `/users/{uid}/progress/{storyId}`. `FirebaseStoryProgressRepository` reads this path, and `submitAttempt` writes it.
- `FirebaseProgressRepository.getProgress` instead reads `/progress/{uid}` as an aggregate `CloudProgress` document. The existing function does not maintain that root aggregate, so this reader and the story-progress writer do not describe the same projection.
- The `users/{uid}` document is created with only `uid`, `email`, and `createdAt`. Firestore rules permit only those fields at creation and prohibit client updates. `submitAttempt` and `awardVocabularyBonus` require `approvalStatus == "approved"`, but the current profile creation path does not set that field. Consequently, a profile created by the current path does not meet the Cloud Function precondition.
- `FirebaseProfileRepository` can create/read a minimal profile, but its `UserProfile` reads `displayName`; the current cloud profile writer does not populate it. The model, `docs/DATA_MODEL.md`, rules, auth model, and function preconditions are not aligned.
- Client writes to attempts and progression are intentionally denied by `firestore.rules`; this is consistent with server authority, but requires all authoritative mutations to pass through trusted functions.
- Existing Functions transactionally write the attempt, total XP, and story progress. This is a useful basis, but the duplicate-attempt existence check is outside the transaction. Concurrent requests using the same operation ID must be made race-safe inside the transaction.
- The server’s chapter progression mapping is hard-coded. It must not be used as the durable cross-device rule as new stories/branches are added.
- The callable requires exactly five question IDs. The shipped local challenge banks include banks with fewer than five questions; the Firebase adapter can return such a bank unchanged. Those attempts will be rejected unless the contract and bank-selection rules are reconciled.
- The application’s selected providers use local story, challenge, and progress repositories. The Firebase challenge/story implementations and Firebase story-progress repository are not selected in `providers.dart`. `authMode` is Firebase, while `dataMode` is local. Therefore existing cloud functions are not the current gameplay sync path.
- When cloud data mode is enabled, `cloudDataProvider` may create a missing profile as part of the read bootstrap; this is separate from gameplay synchronization and is not an outbox.

### Capability evaluation

| Capability | Current schema support | Assessment |
|---|---|---|
| Multi-device sync | UID-scoped cloud documents and attempt records exist, but active gameplay is local and no reconciliation exists. | **Not currently supported.** The path shapes can be a starting point after owners, IDs, and writer/reader paths are unified. |
| Conflict resolution | Completed chapter ID array plus mutable current-unlock scalar; XP total; no profile revisions or generic operation ledger. | **Partial only.** Completion can be monotonic if server-validated; current unlock and scalar totals are not enough to resolve all races safely. |
| Offline operation | Local SharedPreferences storage exists. Cloud progression writes are server-only. | **Local-only offline.** Firestore caching cannot replace a durable local outbox or make a callable run offline. |
| Event replay | Attempts are stored as records, but not every learner mutation is represented by a shared stable event; client retry IDs are not persisted/reused consistently. | **Not generally replayable.** Use immutable event/command IDs and server-side deduplication. |
| Future Cloud Functions | Functions own scoring, XP, and progression and use a transaction. | **Good foundation with blockers:** profile approval/schema mismatch, transaction idempotency race, hard-coded unlock mapping, and attempt-size contract mismatch. |

## 4. XP Synchronization Strategy

### Option comparison

| Strategy | Benefits | Risks | Migration impact | Complexity |
|---|---|---|---|---|
| **A. Synchronize total XP only** | Small payload; simple display; easy to add as a profile field. | Concurrent device writes can overwrite each other; replay may double increment or reset totals; no evidence or audit trail for an award; a client total is forgeable. | Existing local totals can be copied only as a legacy snapshot, not safely treated as verified awards. | Low initially; high later when correcting conflicts, fraud, or duplicate rewards. |
| **B. Synchronize XP award events** | Each award is attributable, auditable, replay-safe, and mergeable by unique event ID; totals can be rebuilt; supports server validation and future reward types. | More records and server logic; event lifecycle/retention and projections need design; legacy totals may have no provable award history. | Preserve old local total as an explicitly labeled legacy opening balance or leave it unverified according to product policy; do not fabricate historical events. | Moderate; best long-term foundation. |

### Recommendation

Choose **B: XP award events as the authoritative ledger**, with `users/{uid}.totalXp` retained only as a server-maintained projection/cache for fast reads.

Only a trusted server transaction may create an XP award event and increment the total. A quiz submission event is a request to grade, not proof of an XP award. The server validates and records the result once using its stable attempt/event ID. Vocabulary bonus awards likewise need a unique server-side award key (for example, user + chapter + bonus type) and must be created atomically with the XP projection update.

- **Benefit:** retries and multiple devices converge on the same ledger and total.
- **Risk:** event history and the aggregate can disagree if not updated atomically; reconcile by recomputing or repairing the projection from the ledger.
- **Migration impact:** existing local totals and attempt records may be client-produced. Preserve them as legacy/local history; do not silently convert unverified XP into trusted award events. Product must decide whether to import a labeled opening balance.
- **Complexity:** medium. Functions already calculate XP and use `FieldValue.increment`, but need transactional deduplication, a durable award record, and tests for concurrent replay.

## 5. Story Progression Strategy

Use a **hybrid event + state projection**:

- **Event facts:** immutable server-accepted `quiz_attempt_accepted` / `chapter_passed` records provide evidence of completion and replay/audit capability.
- **State projection:** keep a compact per-user/per-story progress document for fast reads, containing validated completed chapter IDs, a projection version/updated timestamp, and optionally a derived next playable chapter.
- **Completion:** derive story completion from the canonical chapter catalog and validated completed chapters. Do not separately sync a boolean that can diverge from chapter facts.
- **Unlocks:** derive the next available chapter from the canonical ordering/prerequisite rules and the validated completion set. Do not merge `currentUnlockedChapterId` by ordinary last-write-wins or accept the lexicographically/numerically greatest arbitrary ID.

This makes progression **event-based for writes and evidence, state-based for reads and display**. An offline quiz can be stored locally as pending, but it must not be shown as an authoritative pass or grant cloud XP/unlocks until accepted. Completion facts merge by set union only after server validation. The unlock projection must be recomputed deterministically; the current scalar can regress when an older chapter completion is processed after a newer one.

## 6. Vocabulary Progression

### Current model and risks

The local record already resembles an activity event: generated record ID, chapter, language, word, activity type, correctness, and completion time. However, the serialized local list is truncated to the newest 100; it has no stable vocabulary item/concept ID, no cumulative mastery state, and no defined mastery algorithm. The current count is distinct surface forms by language, not learning or mastery.

- **Duplicate risk:** retries, repeated practice, or the same concept in multiple languages/devices can create duplicate activity. A locally generated ID helps only if reused across retry.
- **Data-loss risk:** records beyond the newest 100 are dropped from persistence. A future count or mastery projection based only on retained history can decrease or become irreproducible.
- **Merge strategy:** immutable union by globally unique event ID; aggregate per stable `conceptId`/`vocabularyItemId`, not localized spelling. Repeated legitimate practice remains separate events, not duplicate concepts.

### Recommendation

Give each vocabulary concept a stable content ID shared across translations, and each learner interaction a stable `eventId` generated once and retained through retries. Persist activity outcome and timestamp; compute mastery from deduplicated evidence using an explicitly product-approved rule (for example, repeated correct recall across separate sessions, with incorrect attempts retained). Do not use a raw maximum counter or merge “mastered” booleans by last-write-wins. If a mastered flag is exposed for reads, treat it as a server-derived projection that can be recalculated from evidence.

Keep XP bonuses separate from vocabulary mastery. A practice event can sync as learner activity, but it must not directly grant XP; the chapter bonus should be a separate idempotent server award.

## 7. Conflict Resolution Rules

| Data type | Merge strategy | Conflict strategy | Expected resolution |
|---|---|---|---|
| XP | Add unique, server-created award events; maintain total as a projection. | Transactional idempotency by award/attempt ID; client totals are never authoritative. | Each accepted award contributes once. Rebuild/repair total from the authoritative ledger if needed. |
| Story completion | Union of server-validated chapter completion facts. | Reject or quarantine unvalidated client completion claims; derive whole-story completion from the catalog. | A valid completion is monotonic and does not disappear because another device is stale. |
| Chapter unlocks | Recompute from the canonical prerequisite/order rules and validated completion set. | Do not merge a single unlock scalar by last-write-wins or greatest ID; validate the chapter belongs to the story. | All devices derive the same next playable chapter; a stale write cannot relock later valid progress. |
| Vocabulary progress | Union immutable events by `eventId`; aggregate by stable concept ID. | Same ID + same payload is a retry; same ID + different payload is rejected. Mastery is derived by a versioned rule. | No lost evidence; duplicate retries count once; legitimate repeat attempts remain visible. |
| Profile data | Field-level updates with field ownership and revisions. | Firebase Auth owns verified identity/email; server owns approval and XP; user-editable fields such as nickname/language use conditional revision or deterministic last-accepted update. | Unrelated fields do not overwrite each other; clients cannot alter server-owned fields. |
| Reading position (supporting data) | Latest position per user/story/chapter. | Last accepted server version/time with mutation-ID tie-break; coalesce unsent local positions. | A deterministic most-recent position wins; loss of intermediate scroll offsets is acceptable. |

## 8. Source of Truth

Recommend **local-first capture with server-authoritative canonical progression** (a deliberate hybrid, not “local total is final”).

- **Offline support:** persist reading position, vocabulary activity, and quiz submissions locally without requiring connectivity.
- **Reliability:** capture local work immediately; retry durable events rather than making gameplay depend on a request staying online.
- **Educational use case:** learners can continue reading/practicing offline, while visible grading/rewards remain trustworthy and consistent.
- **Current architecture:** local repositories already form a working offline base; existing security rules and Cloud Functions already point toward trusted-server grading and XP.

Use explicit pending/accepted/failed states. A queued quiz is pending; only a server response marks it graded and awards XP/unlocks. Display the last confirmed cloud total separately from pending activity. Never silently switch a Firebase UID into an unrelated local identity during outages.

## 9. Proposed Sync Event Model (Design Only)

Separate the immutable event payload from mutable local queue metadata.

### Immutable event envelope

```json
{
  "eventId": "uuid-v4-created-once",
  "schemaVersion": 1,
  "userId": "firebase-auth-uid",
  "deviceId": "random-installation-id",
  "type": "quiz_attempt_submitted",
  "aggregateId": "attempt-id-or-story/concept-id",
  "occurredAt": "UTC client timestamp",
  "payload": {}
}
```

`userId` is bound from the authenticated Firebase session at enqueue and rechecked at send time. `deviceId` is a random installation identifier, not a hardware fingerprint. Client timestamps are descriptive only; server receipt/acceptance timestamps determine authoritative ordering. Do not put sync attempt counts, errors, or queue state in the immutable event payload.

### Recommended client event types

- `quiz_attempt_submitted`: attempt ID, story/chapter/challenge IDs, bank version, question IDs, selected stable option IDs, and any fields required by the scoring contract. It is an untrusted request, not a grade.
- `vocabulary_activity_recorded`: activity ID/type, stable vocabulary concept ID, chapter/language context, outcome, and occurrence time.
- `reading_position_set`: story/chapter IDs and position; intermediate unsent events may be coalesced per chapter.
- `profile_preference_changed`: only explicitly user-editable fields and their base revision, if profile sync is in scope.

`quiz_attempt_accepted`, `chapter_passed`, `xp_awarded`, and progression projections are **server-produced results**, not client-authoritative events. A client must not submit an `xp_awarded` event or a claim that a chapter has been passed.

### Idempotency, duplicates, and retention

- Generate the event/operation ID once when the local action is committed; persist it and reuse it for every retry.
- Use the event ID as the server idempotency key. Create/check the idempotency record and apply side effects in the same Firestore transaction. Same ID/same payload returns the prior result; same ID/different payload is rejected.
- Also enforce domain-specific uniqueness where appropriate (e.g. one vocabulary bonus per user/chapter/bonus type), because a caller could create a second UUID for the same logical reward.
- Retain canonical accepted quiz/award evidence according to an explicit product/privacy retention policy. Do not TTL-delete the only evidence needed to audit/rebuild XP or progression. Prune acknowledged local outbox payloads after a confirmed response; keep only the minimal local acknowledgement/checkpoint needed for recovery.

## 10. Proposed Outbox Queue (Design Only)

| Concern | Recommendation |
|---|---|
| Storage | SQLite-backed durable table, not a single growing SharedPreferences JSON value. Store event payload and queue metadata transactionally with the local domain change. Use schema migrations and indexes for per-user status/creation order. |
| Scope | Partition/associate every item with a Firebase UID. Never send queued data under a different signed-in user. Keep guest/local-only data isolated until an explicit, verified account-link migration is approved. |
| Lifecycle | `pending` → `in_flight` (leased with expiry) → `acknowledged`; transient failure returns to `pending` with a retry time; permanent validation/auth/rules failure goes to visible `needs_attention`/dead-letter state. On app launch/resume, successful auth, and connectivity restoration, drain eligible items in bounded batches. |
| Ordering | Preserve per-aggregate causal order where actions depend on one another (attempt/result/progression); independent vocabulary and reading-position items can batch. Server projection remains authoritative. |
| Retry | Exponential backoff with full jitter and a maximum delay (e.g. 15 minutes). Retry network/unavailable/deadline errors. Do not endlessly retry invalid payload, permission, or account mismatch errors; surface them and retain the record for recovery. |
| Failure handling | Never silently drop. Record a sanitized error code and last attempt time; do not persist secrets or full sensitive diagnostics. On auth change, pause and retain rather than reassign. A server rejection must not be represented as success. |
| Coalescing | Coalesce superseded unsent reading-position updates for the same user/story/chapter. Do not coalesce quiz attempts, XP awards, or vocabulary evidence. |
| Maximum | Initial operational limit: **5,000 pending events or 10 MiB per UID/device, whichever is reached first**, with a warning at 80%. Tune from measured usage. Never evict unacknowledged quiz/vocabulary events to satisfy the limit. At capacity, show an explicit sync-capacity error and do not claim new work is queued; retain local work and require recovery/sync before accepting further sync-dependent actions. |
| Cleanup | After server acknowledgement, remove the local payload/queue row once local state and server result are safely reconciled. Keep canonical server records under a documented retention policy. Do not purge pending or `needs_attention` events automatically. |
| Batching | Send bounded batches (initially 50 events or less, subject to callable/request size limits); acknowledge each operation/result explicitly so a partial batch failure is safe to retry. |

SQLite is a design prerequisite, not a request to implement it in this review. A migration must preserve current local progress, reading position, attempts, vocabulary records, XP, and bonus markers before changing storage.

## 11. Risk Analysis

| Risk | Severity | Why it matters | Required mitigation |
|---|---|---|---|
| Local and cloud state have no reconciliation path | Critical | A second device starts from a separate history; offline changes do not converge. | Define UID-bound outbox, event contracts, merge behavior, and migration before sync activation. |
| Profile creation and Function preconditions disagree | Critical | Current minimal profile lacks `approvalStatus`, while functions require it to be approved; server submissions can fail. | Align approval lifecycle, schema, rules, and function validation; test allowed profile states. |
| Cloud progress read/write paths disagree | High | Root aggregate reader does not read the per-story documents written by the function. | Choose one canonical path/projection and update schema, readers, functions, indexes, and rules consistently. |
| Repository interface bypassed | High | UI only persists key progress when runtime repository is `LocalProgressRepository`; switching implementations silently skips those mutations. | Replace concrete-type branches with explicit repository/use-case contracts and contract tests. |
| XP/attempt/progression updates are split in the active local path | High | A process failure can persist one side effect without the other; retry may award twice. | Local atomic commit plus stable operation ID; server transaction for authoritative result and award. |
| Function idempotency check can race | High | Duplicate concurrent calls can both pass the pre-transaction existence check. | Check/create the idempotency record inside the transaction and test concurrent duplicate calls. |
| Current unlock scalar can regress | High | An older completion can overwrite a later unlock when requests arrive out of order. | Derive unlocks from validated completed chapters and canonical progression rules. |
| Local vocabulary history is capped at 100 and has no concept ID/mastery semantics | High | Old evidence is lost and cross-language/device aggregation is unreliable. | Stable concept IDs, durable event history/retention, deduplication, and a versioned mastery definition. |
| Existing Cloud Function’s five-question contract does not cover all shipped banks | High | Banks with fewer than five questions may be returned unchanged by the Firebase adapter, but the function rejects them. | Agree on minimum/question-count policy and enforce the same contract in client, content, and server tests. |
| Legacy local progress is not proof of server-graded results | High | Blind import could create unverified chapter unlocks and XP. | Preserve backup; classify legacy evidence and require product-approved migration policy. |
| Profile ownership is ambiguous | Medium | Auth model, profile model, Firestore schema, and Function checks differ. | Define field-level authority and ensure clients cannot write approval/XP. |
| Queue growth or permanent failures are hidden | Medium | Silent loss or unbounded storage can undermine trust and multi-device state. | Bounded durable queue, visible failure state, retention, capacity handling, and telemetry without sensitive payloads. |

## 12. Recommended Architecture

```text
UI / feature use cases
        |
Domain repository interfaces
        |
Local transactional store (current state + durable outbox)
        |                           \
        |                            \ Sync worker (auth/network/app-resume)
        |                                      |
        |                         authenticated callable/API commands
        |                                      |
        |                         trusted Cloud Functions + transactions
        |                                      |
        +---- local-first reads <--- server projections / accepted results
```

1. **Local capture:** atomically store domain activity and its outbox operation before showing it as saved.
2. **Server validation:** Functions validate identity, schema, chapter/question membership, approval, and replay keys. Client-authored quiz results are not authoritative.
3. **Server ledger/projections:** record accepted attempts and XP awards idempotently; update per-user story progress and XP projection in the same transaction.
4. **Read/reconcile:** return accepted result and current projection; merge monotonically where defined; keep pending and confirmed state distinct.
5. **Content:** keep published stories, chapters, translations, and challenges separate from learner-owned records.
6. **Rules:** preserve server-only authority for XP, quiz grades, unlocks, and accepted attempts. Add only narrowly scoped client writes if a data type is explicitly safe for them; otherwise use validated server endpoints.

## 13. Phase 3 Implementation Plan

Do not begin with a queue implementation against the current models. Recommended order:

1. **Resolve contracts and ownership:** decide which state is canonical, define event and command schemas, profile fields/approval lifecycle, event retention, mastery rules, and legacy XP policy.
2. **Align cloud schema:** choose canonical progress paths; reconcile profile/progress models, rules, Functions, seed data, read repositories, and question-count requirements.
3. **Add characterization and emulator gates:** establish local behavior tests and Firebase emulator tests for rules, callable validation, concurrent duplicate submissions, XP awards, unlock ordering, and failure cases.
4. **Introduce local durable persistence:** migrate SharedPreferences data non-destructively into a transactional SQLite store. Preserve backups and verify counts/state; do not implicitly trust old client-produced scores or XP.
5. **Define repository mutation contracts:** make attempt, vocabulary, reading-position, and profile operations available through abstractions; remove UI dependence on concrete local repository types.
6. **Implement server idempotency and projections:** transactionally deduplicate operation IDs, create server-owned award/accepted-attempt records, update XP and progress projections, and compute unlocks from canonical progression rules.
7. **Implement the outbox and worker:** stable IDs, UID binding, leases, bounded batch, jittered retry, visible permanent failures, acknowledgement/reconciliation, and capacity handling.
8. **Implement vocabulary identity and aggregation:** stable concept IDs, event retention, dedupe, and a specified mastery algorithm; keep bonus XP independently idempotent.
9. **Migrate and reconcile safely:** verified account association, explicit legacy import policy, backups, audit results, and rollback path.
10. **Roll out gradually:** emulator first, internal multi-device tests, guarded cohort/feature flag, observability and support procedures, then broader enablement only after success criteria pass.

### Minimum Phase 3 exit gates

- No client can create or mutate authoritative XP, grade, attempt acceptance, or chapter unlock state.
- Replaying one event ID (including concurrent replay) never duplicates a result or award.
- Two devices converge after offline/online transitions without losing accepted completion or vocabulary evidence.
- Out-of-order events cannot relock a chapter or overwrite newer valid progress.
- Local data survives restart, migration, network failure, auth changes, and queue-capacity conditions.
- Function/rules tests cover profile approval, ownership, invalid payloads, and all shipped challenge-bank sizes.
- Users can distinguish pending work, confirmed cloud progress, and permanent sync errors.

## 14. Readiness Report

### Strengths

- Riverpod provider wiring gives a natural seam for local/cloud adapters.
- Local progress, XP, and reading positions already have persistence and basic restart tests.
- Learner IDs are represented explicitly in local progress storage.
- Quiz snapshots and vocabulary activity records already contain some event-like fields.
- Firestore rules deny direct client writes to progression and attempt records.
- `submitAttempt` performs scoring and multiple cloud writes in a Firestore transaction; a vocabulary-bonus Function also uses a transaction.
- Existing documentation contains a useful hybrid roadmap and local migration precautions; reconcile it with the current active code before implementation.

### Weaknesses

- Firebase identity and gameplay storage are split; no local-to-cloud identity/data migration exists.
- Firebase profile and progress data models/paths do not align with rules and Function prerequisites.
- Local progress writes are concrete-only and persistence is a whole SharedPreferences JSON document, not a transactional outbox.
- XP, quiz history, chapter completion, and bonuses have different owners and are not an atomic local operation.
- No shared event contract, conflict protocol, queue, retry lifecycle, or acknowledged/pending user state exists.
- Vocabulary activity is truncated and measures practice, not mastery.
- Existing server progression is hard-coded and has a replay race; bank/question-count expectations are not consistent for every shipped bank.

### Required changes before sync

1. Align profile/approval creation and server validation.
2. Align root/per-user progress paths and the canonical read model.
3. Define event IDs, idempotency, authoritative XP ledger/projection, completion evidence, and unlock derivation.
4. Introduce a durable local transactional store/outbox and explicit pending vs accepted semantics.
5. Replace concrete repository checks with complete mutation contracts.
6. Define stable vocabulary concepts, mastery, retention, and legacy migration policies.
7. Add emulator coverage for rules and Functions, including concurrent replay and all shipped question counts.

### Optional improvements

- Add field revisions for editable profile preferences.
- Add privacy-aware sync diagnostics and a user-visible “last synced”/pending count.
- Track per-device sync checkpoints without using hardware identifiers.
- Consolidate prior architecture/roadmap docs after validating them against active code; older roadmap statements about repository wiring and XP behavior should not be assumed current.

### Final Go / No-Go Recommendation

**NO-GO for enabling Phase 3 hybrid sync against the current architecture.** **GO for Phase 3 prerequisite work** once this design is accepted. Reassess the gate after the minimum exit criteria pass in emulator and multi-device tests. This review makes no production behavior changes and does not implement any sync component.
