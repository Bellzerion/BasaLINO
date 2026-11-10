import 'cloud_progress_model.dart';
import 'user_profile_model.dart';

enum CloudDataStatus { loaded, missingProfile, localFallback }

class CloudDataState {
  const CloudDataState({
    required this.status,
    this.profile,
    this.progress,
    this.message,
  });

  final CloudDataStatus status;
  final UserProfile? profile;
  final CloudProgress? progress;
  final String? message;
}
