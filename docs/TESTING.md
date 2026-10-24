# BasaLINO Testing Strategy

## 1. Unit Testing
- Business logic validation in `test/progression_rules_test.dart`:
  - 60% passing threshold for unlocking chapters.
  - XP award calculation (+10 XP per question, +5 XP 100% bonus).
  - Chapter status state evaluations.
  - User model approval status verification.

Execute unit tests:
```bash
flutter test test/progression_rules_test.dart
```

## 2. Widget & Presentation Testing
- Test story list loading and display.
- Test reader text resizing and vocabulary bottom sheet.
- Test comprehension quiz selection and feedback.

## 3. Firebase Security Rules & Cloud Functions Testing
- Test suite in `functions/test/`:
  - Verify unauthorized clients cannot read `challengeKeys`.
  - Verify client writes to `users/{uid}/totalXp` are rejected.
  - Verify idempotent attempt submissions prevent duplicate XP awards.
