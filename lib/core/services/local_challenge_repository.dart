import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/challenge_model.dart';
import '../models/attempt_result_model.dart';
import '../services/challenge_repository.dart';

class LocalChallengeRepository implements ChallengeRepository {
  List<Map<String, dynamic>>? _cachedChallenges;
  Map<String, dynamic>? _cachedKeys;
  final _uuid = const Uuid();

  Future<List<Map<String, dynamic>>> _loadChallenges() async {
    if (_cachedChallenges != null) return _cachedChallenges!;
    final jsonStr = await rootBundle.loadString('assets/data/challenges.json');
    final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
    _cachedChallenges = data.map((e) => e as Map<String, dynamic>).toList();
    return _cachedChallenges!;
  }

  Future<Map<String, dynamic>> _loadKeys() async {
    if (_cachedKeys != null) return _cachedKeys!;
    final jsonStr = await rootBundle.loadString('assets/data/challenge_keys.json');
    _cachedKeys = jsonDecode(jsonStr) as Map<String, dynamic>;
    return _cachedKeys!;
  }

  @override
  Future<ChallengeModel?> getChallenge({
    required String chapterId,
    required String languageCode,
    List<String> excludedQuestionIds = const [],
  }) async {
    final list = await _loadChallenges();
    // Look for exact match
    var match = list.firstWhere(
      (e) => e['chapterId'] == chapterId && e['languageCode'] == languageCode,
      orElse: () => {},
    );
    // Fallback to English challenge if translation doesn't exist
    if (match.isEmpty) {
      match = list.firstWhere(
        (e) => e['chapterId'] == chapterId && e['languageCode'] == 'en',
        orElse: () => {},
      );
    }
    if (match.isEmpty) return null;
    final bank = ChallengeModel.fromMap(match['id'] as String, match);
    if (bank.questions.length <= 5) return bank;

    final excluded = excludedQuestionIds.toSet();
    final eligible = bank.questions.where((q) => !excluded.contains(q.id)).toList();
    final fallback = bank.questions.where((q) => excluded.contains(q.id)).toList();
    eligible.shuffle(Random());
    fallback.shuffle(Random());
    final selected = <ChallengeQuestionModel>[...eligible.take(5)];
    if (selected.length < 5) selected.addAll(fallback.take(5 - selected.length));

    final shuffled = selected
        .map((question) => ChallengeQuestionModel(
              id: question.id,
              questionText: question.questionText,
              options: [...question.options]..shuffle(Random()),
              skill: question.skill,
              difficulty: question.difficulty,
            ))
        .toList()
      ..shuffle(Random());
    return ChallengeModel(
      id: bank.id,
      chapterId: bank.chapterId,
      languageCode: bank.languageCode,
      version: bank.version,
      questions: shuffled,
    );
  }

  @override
  Future<AttemptResultModel> submitAttempt({
    required String challengeId,
    required String chapterId,
    required List<String> questionIds,
    required Map<String, String> answers,
  }) async {
    // In local dev/mock mode, validate against challenge_keys.json (in prod, server-side function does this)
    final keys = await _loadKeys();
    final challengeKeyMap = keys[challengeId] as Map<String, dynamic>? ?? {};

    int correct = 0;
    for (final qId in questionIds) {
      final expectedAnswer = challengeKeyMap[qId];
      if (answers[qId] != null && answers[qId]!.trim() == expectedAnswer.toString().trim()) {
        correct++;
      }
    }

    final total = questionIds.length;
    final score = total > 0 ? ((correct / total) * 100).round() : 0;
    final passed = score >= 60; // 60% threshold

    // XP Rule: 10 XP per correct question, +5 bonus if 100%
    int xpAwarded = 0;
    if (passed) {
      xpAwarded = correct * 10;
      if (score == 100) {
        xpAwarded += 5;
      }
    }

    String? nextChapterId;
    if (passed) {
      if (chapterId == 'ibalong_ch1') {
        nextChapterId = 'ibalong_ch2';
      } else if (chapterId == 'ibalong_ch2') {
        nextChapterId = 'ibalong_ch3';
      } else if (chapterId == 'mayon_ch1') {
        nextChapterId = 'mayon_ch2';
      } else if (chapterId == 'mayon_ch2') {
        nextChapterId = 'mayon_ch3';
      }
    }

    return AttemptResultModel(
      attemptId: _uuid.v4(),
      score: score,
      totalQuestions: total,
      correctAnswers: correct,
      xpAwarded: xpAwarded,
      passed: passed,
      nextChapterId: nextChapterId,
    );
  }
}
