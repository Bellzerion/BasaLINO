import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
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
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<ChallengeModel?> getChallenge({
    required String chapterId,
    required String languageCode,
  }) async {
    // Attempt exact challenge
    final snap = await _firestore
        .collection('challenges')
        .where('chapterId', isEqualTo: chapterId)
        .where('languageCode', isEqualTo: languageCode)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return ChallengeModel.fromMap(snap.docs.first.id, snap.docs.first.data());
    }

    // Fallback to English challenge
    final fallbackSnap = await _firestore
        .collection('challenges')
        .where('chapterId', isEqualTo: chapterId)
        .where('languageCode', isEqualTo: 'en')
        .limit(1)
        .get();

    if (fallbackSnap.docs.isNotEmpty) {
      return ChallengeModel.fromMap(fallbackSnap.docs.first.id, fallbackSnap.docs.first.data());
    }

    return null;
  }

  @override
  Future<AttemptResultModel> submitAttempt({
    required String challengeId,
    required String chapterId,
    required Map<String, String> answers,
  }) async {
    final callable = _functions.httpsCallable('submitAttempt');
    final attemptId = _uuid.v4();

    final response = await callable.call({
      'challengeId': challengeId,
      'chapterId': chapterId,
      'storyId': chapterId.split('_').first,
      'answers': answers,
      'attemptId': attemptId,
    });

    final data = Map<String, dynamic>.from(response.data as Map);
    return AttemptResultModel.fromMap(data);
  }
}
