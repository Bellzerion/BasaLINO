# BasaLINO Setup & Development Guide

## Prerequisites
1. **Flutter SDK**: 3.47+ / Dart 3.13+
2. **Node.js**: 18+ (for Firebase Functions & Seed scripts)
3. **Firebase CLI**: `npm install -g firebase-tools`

## Local Development (Phase 1 & Phase 2 Mock Mode)
BasaLINO comes with an in-memory & asset-backed repository suite (`LocalStoryRepository`, `LocalChallengeRepository`, `LocalProgressRepository`, `LocalAuthRepository`), enabling full local development without active Firebase credentials:

```bash
flutter pub get
flutter run
```

## Running with Firebase Emulators (Phase 3+)
1. Start emulators:
   ```bash
   firebase emulators:start
   ```
2. Seed Firestore with initial story and challenge data:
   ```bash
   npm --prefix functions run seed
   ```
3. Launch Flutter app configured for local emulators.
