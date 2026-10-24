# BasaLINO Architecture Decisions (ADR)

## ADR-001: State Management with Riverpod
- **Context:** Need predictable, testable, decoupled state management suitable for Flutter.
- **Decision:** Use `flutter_riverpod`. Repositories and state streams are injected via top-level providers, making unit and widget testing straightforward by overriding providers.

## ADR-002: Router with go_router and Auth Redirection
- **Context:** Need declarative navigation that cleanly handles child-safety/parental approval gates and authentication checks.
- **Decision:** Use `go_router` with a dynamic redirect based on `authStateProvider`. Unapproved accounts are trapped at `/consent-pending` to protect sensitive educational interactions.

## ADR-003: Server-Side Attempt Validation & Answer Keys
- **Context:** Learners should not be able to inspect network calls or bundle resources to extract quiz answer keys or forge XP.
- **Decision:** Challenge answer keys are stored in a dedicated `challengeKeys` Firestore collection (or server-side in Cloud Function scope). Client only submits answers; the `submitAttempt` Cloud Function validates and commits XP/progress.

## ADR-004: Multilingual Translation Fallback Strategy
- **Context:** Content in Bikol or Tagalog may not always have every chapter or question available.
- **Decision:** Fall back gracefully to English rather than throwing an error or leaving blank screens, while flagging unverified translations with an informative tag.
