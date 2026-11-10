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
creation is limited to the canonical bootstrap contract; profile updates,
deletes, and client progress writes are denied.
