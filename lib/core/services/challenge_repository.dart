// lib/core/services/challenge_repository.dart
import '../models/challenge_model.dart';
import '../models/attempt_result_model.dart';

abstract class ChallengeRepository {
  Future<ChallengeModel?> getChallenge({
    required String chapterId,
    required String languageCode,
  });

  /// Submits answers to the server.
  /// [answers] is a map of questionId → chosen answer string.
  Future<AttemptResultModel> submitAttempt({
    required String challengeId,
    required String chapterId,
    required Map<String, String> answers,
  });
}
