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
  - Cloud Functions (TypeScript server-side attempt scoring, answer validation & XP awards)
  - Security Rules (Client read-only for private keys and progression calculations)

## Getting Started
See [SETUP.md](docs/SETUP.md) for local environment setup, Firebase emulator instructions, and seed script execution.
