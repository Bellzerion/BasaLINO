import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_repository.dart';
import '../../core/services/story_repository.dart';
import '../../core/services/challenge_repository.dart';
import '../../core/services/progress_repository.dart';
import '../../core/services/local_auth_repository.dart';
import '../../core/services/local_story_repository.dart';
import '../../core/services/local_challenge_repository.dart';
import '../../core/services/local_progress_repository.dart';
import '../../core/models/user_model.dart';

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository();
});

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return LocalStoryRepository();
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return LocalChallengeRepository();
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final storyRepo = ref.watch(storyRepositoryProvider);
  return LocalProgressRepository(storyRepo);
});

// Auth state stream
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

// Current user snapshot provider
final currentUserProvider = StateProvider<UserModel?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.value;
});

// App current language code state
final appLanguageProvider = StateProvider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.preferredLanguage ?? 'en';
});
