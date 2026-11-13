import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/auth_mode.dart';
import '../../core/services/auth_repository.dart';
import '../../core/services/story_repository.dart';
import '../../core/services/challenge_repository.dart';
import '../../core/services/progress_repository.dart';
import '../../core/services/local_auth_repository.dart';
import '../../core/services/firebase_auth_repository.dart';
import '../../core/services/local_story_repository.dart';
import '../../core/services/local_challenge_repository.dart';
import '../../core/services/local_progress_repository.dart';
import '../../core/models/user_model.dart';
import '../../core/services/progress_mutation_service.dart';
import '../../core/services/firebase_profile_repository.dart';

// Repositories
final authModeProvider = Provider<AuthMode>((ref) => authMode);
final dataModeProvider = Provider<DataMode>((ref) => dataMode);
final firebaseProfileRepositoryProvider = Provider<FirebaseProfileRepository>(
  (ref) => FirebaseProfileRepository(),
);

final localAuthRepositoryProvider = Provider<LocalAuthRepository>((ref) {
  return LocalAuthRepository();
});

final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return switch (ref.watch(authModeProvider)) {
    AuthMode.local => ref.watch(localAuthRepositoryProvider),
    AuthMode.firebase => ref.watch(firebaseAuthRepositoryProvider),
  };
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

final progressMutationServiceProvider = Provider<ProgressMutationService>((ref) {
  return ProgressMutationService(
    progressRepository: ref.watch(progressRepositoryProvider),
    storyRepository: ref.watch(storyRepositoryProvider),
  );
});

// Auth state stream
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final mode = ref.watch(authModeProvider);
  if (mode != AuthMode.firebase || repo is! FirebaseAuthRepository) {
    return repo.authStateChanges;
  }

  final profiles = ref.watch(firebaseProfileRepositoryProvider);
  return repo.authStateChanges.asyncMap((user) async {
    if (user == null) return null;
    await profiles.createProfileIfMissing(uid: user.uid, email: user.email);
    final profile = await profiles.getProfile(user.uid);
    if (profile == null) {
      throw StateError('Authenticated user profile could not be loaded.');
    }
    return user.copyWith(
      nickname: profile.displayName ?? user.nickname,
      preferredLanguage: profile.preferredLanguage,
      approvalStatus: profile.approvalStatus,
    );
  });
});

typedef AuthRoutingState = ({
  bool isAuthenticated,
  ApprovalStatus? approvalStatus,
});

final authRoutingStateProvider = Provider<AuthRoutingState?>((ref) {
  return ref.watch(
    authStateProvider.select((authState) {
      final user = authState.asData?.value;
      if (user == null) return null;
      return (isAuthenticated: true, approvalStatus: user.approvalStatus);
    }),
  );
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
