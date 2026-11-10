# BasaLINO — Gamified Multilingual Philippine Reading App (MVP)

BasaLINO is a gamified, multilingual Philippine reading application built with Flutter, Riverpod, go_router, and Firebase. It encourages learners to discover local stories, explore vocabulary hints, and test their reading comprehension to earn XP and unlock consecutive chapters.

## Supported Languages
- English (`en`)
- Tagalog (`tl`)
- Bikol (`bik` - Central Bikol)

## Architecture Overview
- **UI Framework:** Flutter (Material 3)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Navigation:** `go_router`
- **Backend & Cloud Services:**
  - Firebase Authentication (Email/Password, Nickname)
  - Cloud Firestore (Stories, Chapters, Challenges, Progress)
  - Optional read-only profile and progress reads (`DataMode.cloud`)
  - Cloud Functions (TypeScript server-side attempt scoring, answer validation & XP awards)
  - Security Rules (Client read-only for private keys and progression calculations)

Cloud reads are disabled by default (`DataMode.local`). To enable them, set
`dataMode` to `DataMode.cloud` in `lib/core/config/auth_mode.dart`. Cloud reads
use `users/{uid}` and `progress/{uid}`; the only client write in this phase is
creating the authenticated user's minimal profile document when it is missing.
Gameplay progress continues to use local repositories.

## Getting Started
See [SETUP.md](docs/SETUP.md) for local environment setup, Firebase emulator instructions, and seed script execution.
