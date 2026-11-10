import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/auth_mode.dart';
import '../../core/models/cloud_data_state.dart';
import '../../core/services/firebase_progress_repository.dart';
import '../../core/services/firebase_profile_repository.dart';
import 'providers.dart';

const _cloudReadTimeout = Duration(seconds: 10);

final firebaseProfileRepositoryProvider = Provider<FirebaseProfileRepository>(
  (ref) => FirebaseProfileRepository(),
);

final firebaseProgressRepositoryProvider = Provider<FirebaseProgressRepository>(
  (ref) => FirebaseProgressRepository(),
);

final cloudDataProvider = FutureProvider<CloudDataState?>((ref) async {
  if (ref.watch(dataModeProvider) != DataMode.cloud ||
      ref.watch(authModeProvider) != AuthMode.firebase) {
    return null;
  }

  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) return null;

  final profileRepository = ref.watch(firebaseProfileRepositoryProvider);
  final progressRepository = ref.watch(firebaseProgressRepositoryProvider);

  try {
    final exists = await profileRepository
        .profileExists(user.uid)
        .timeout(_cloudReadTimeout);
    if (!exists) {
      await profileRepository
          .createProfileIfMissing(uid: user.uid, email: user.email)
          .timeout(_cloudReadTimeout);
    }

    final profile = await profileRepository
        .getProfile(user.uid)
        .timeout(_cloudReadTimeout);
    if (profile == null) {
      return const CloudDataState(
        status: CloudDataStatus.missingProfile,
        message: 'Your cloud profile is not available. Your local progress is still available.',
      );
    }

    try {
      final progress = await progressRepository
          .getProgress(user.uid)
          .timeout(_cloudReadTimeout);
      return CloudDataState(
        status: CloudDataStatus.loaded,
        profile: profile,
        progress: progress,
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Cloud progress read failed (${error.code}): $stackTrace');
      return CloudDataState(
        status: CloudDataStatus.localFallback,
        profile: profile,
        message: _fallbackMessage(error),
      );
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('Cloud progress read timed out: $error\n$stackTrace');
      return CloudDataState(
        status: CloudDataStatus.localFallback,
        profile: profile,
        message: 'Cloud data took too long to load. Your local progress is still available.',
      );
    } on FormatException catch (error, stackTrace) {
      debugPrint('Cloud progress data is invalid: $error\n$stackTrace');
      return CloudDataState(
        status: CloudDataStatus.localFallback,
        profile: profile,
        message: 'Cloud progress could not be read. Your local progress is still available.',
      );
    }
  } on FirebaseException catch (error, stackTrace) {
    debugPrint('Cloud profile read failed (${error.code}): $stackTrace');
    return CloudDataState(
      status: CloudDataStatus.localFallback,
      message: _fallbackMessage(error),
    );
  } on TimeoutException catch (error, stackTrace) {
    debugPrint('Cloud profile read timed out: $error\n$stackTrace');
    return const CloudDataState(
      status: CloudDataStatus.localFallback,
      message: 'Cloud data took too long to load. Your local progress is still available.',
    );
  } on FormatException catch (error, stackTrace) {
    debugPrint('Cloud profile data is invalid: $error\n$stackTrace');
    return const CloudDataState(
      status: CloudDataStatus.localFallback,
      message: 'Cloud profile could not be read. Your local progress is still available.',
    );
  }
});

String _fallbackMessage(FirebaseException error) {
  if (error.code == 'permission-denied') {
    return 'Cloud data is not accessible. Your local progress is still available.';
  }
  if (error.code == 'unavailable' ||
      error.code == 'network-request-failed' ||
      error.code == 'deadline-exceeded') {
    return 'Cloud data is offline. Your local progress is still available.';
  }
  return 'Cloud data could not be loaded. Your local progress is still available.';
}
