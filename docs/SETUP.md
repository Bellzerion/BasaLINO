# BasaLINO Setup & Development Guide

## Prerequisites
1. **Flutter SDK**: 3.47+ / Dart 3.13+
2. **Node.js**: 18+ (for Firebase Functions & Seed scripts)
3. **Firebase CLI**: `npm install -g firebase-tools`

## Local Development
BasaLINO comes with an in-memory & asset-backed repository suite (`LocalStoryRepository`, `LocalChallengeRepository`, `LocalProgressRepository`, `LocalAuthRepository`), enabling full local development without active Firebase credentials:

```bash
flutter pub get
flutter run
```

Firestore profile and progress reads are disabled by default. To opt in, set
`dataMode` to `DataMode.cloud` in `lib/core/config/auth_mode.dart`. When enabled,
the app reads profile data from `users/{uid}` and story progress from
`users/{uid}/progress/{storyId}`. Profile bootstrap creates the canonical
profile fields documented in [PHASE3_FOUNDATION.md](./PHASE3_FOUNDATION.md).
Read errors leave the existing local repositories available; gameplay does not
write cloud progress.

## Running with Firebase Emulators
1. Start emulators:
   ```bash
   firebase emulators:start
   ```
2. Seed Firestore with initial story and challenge data:
   ```bash
   npm --prefix functions run seed
   ```
3. Launch Flutter app configured for local emulators.

Apply `firestore.rules` when deploying or using the emulator. Rules allow a
signed-in user to read only their own profile and progress documents. Profile
bootstrap creates a pending profile; approval changes and progress writes are
server-only.

## Contract emulator tests

Install the Functions package dependencies once:

```bash
npm --prefix functions install
```

Run the Functions build and contract tests with Auth, Firestore, and Functions
emulators:

```bash
npm --prefix functions run build
firebase emulators:exec --project demo-basalino --only auth,firestore,functions "npm --prefix functions run test:emulator"
```

The suite checks profile validation/ownership, pending approval enforcement,
variable-length question submission, canonical progress reads/projections,
concurrent attempt idempotency, and one-time vocabulary bonus awards. It uses
only emulator data and does not write to a production Firebase project.
