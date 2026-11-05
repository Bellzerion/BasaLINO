// lib/core/services/challenge_repository.dart
import '../models/challenge_model.dart';
import '../models/attempt_result_model.dart';

abstract class ChallengeRepository {
  Future<ChallengeModel?> getChallenge({
    required String chapterId,
    required String languageCode,
    List<String> excludedQuestionIds = const [],
  });

  /// Submits answers to the server.
  /// [answers] is a map of questionId → stable selected option ID.
  Future<AttemptResultModel> submitAttempt({
    required String challengeId,
    required String chapterId,
    required List<String> questionIds,
    required Map<String, String> answers,
  });
}
