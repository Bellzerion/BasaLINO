import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import 'dart:math';

import '../models/challenge_model.dart';
import '../models/attempt_result_model.dart';
import '../services/challenge_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseChallengeRepository implements ChallengeRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final _uuid = const Uuid();

  FirebaseChallengeRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<ChallengeModel?> getChallenge({
    required String chapterId,
    required String languageCode,
    List<String> excludedQuestionIds = const [],
  }) async {
    // Attempt exact challenge
    final snap = await _firestore
        .collection('challenges')
        .where('chapterId', isEqualTo: chapterId)
        .where('languageCode', isEqualTo: languageCode)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return _select(
        ChallengeModel.fromMap(snap.docs.first.id, snap.docs.first.data()),
        excludedQuestionIds,
      );
    }

    // Fallback to English challenge
    final fallbackSnap = await _firestore
        .collection('challenges')
        .where('chapterId', isEqualTo: chapterId)
        .where('languageCode', isEqualTo: 'en')
        .limit(1)
        .get();

    if (fallbackSnap.docs.isNotEmpty) {
      return _select(
        ChallengeModel.fromMap(
          fallbackSnap.docs.first.id,
          fallbackSnap.docs.first.data(),
        ),
        excludedQuestionIds,
      );
    }

    return null;
  }

  ChallengeModel _select(ChallengeModel bank, List<String> excludedIds) {
    if (bank.questions.length <= ChallengeModel.maxAttemptQuestionCount) {
      return bank;
    }
    final excluded = excludedIds.toSet();
    final eligible =
        bank.questions.where((q) => !excluded.contains(q.id)).toList()
          ..shuffle(Random());
    final fallback =
        bank.questions.where((q) => excluded.contains(q.id)).toList()
          ..shuffle(Random());
    final remaining = (ChallengeModel.maxAttemptQuestionCount - eligible.length)
        .clamp(0, ChallengeModel.maxAttemptQuestionCount)
        .toInt();
    final questions = [
      ...eligible.take(ChallengeModel.maxAttemptQuestionCount),
      ...fallback.take(remaining),
    ];
    questions.shuffle(Random());
    return ChallengeModel(
      id: bank.id,
      chapterId: bank.chapterId,
      languageCode: bank.languageCode,
      version: bank.version,
      questions: questions,
    );
  }

  @override
  Future<AttemptResultModel> submitAttempt({
    required String challengeId,
    required String chapterId,
    required List<String> questionIds,
    required Map<String, String> answers,
  }) async {
    final callable = _functions.httpsCallable('submitAttempt');
    final attemptId = _uuid.v4();

    final response = await callable.call({
      'challengeId': challengeId,
      'chapterId': chapterId,
      'storyId': chapterId.split('_').first,
      'questionIds': questionIds,
      'answers': answers,
      'attemptId': attemptId,
    });

    final data = Map<String, dynamic>.from(response.data as Map);
    return AttemptResultModel.fromMap(data);
  }
}
