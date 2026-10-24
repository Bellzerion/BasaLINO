import 'dart:convert';
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
    return ChallengeModel.fromMap(match['id'] as String, match);
  }

  @override
  Future<AttemptResultModel> submitAttempt({
    required String challengeId,
    required String chapterId,
    required Map<String, String> answers,
  }) async {
    // In local dev/mock mode, validate against challenge_keys.json (in prod, server-side function does this)
    final keys = await _loadKeys();
    final challengeKeyMap = keys[challengeId] as Map<String, dynamic>? ?? {};

    int correct = 0;
    challengeKeyMap.forEach((qId, expectedAnswer) {
      if (answers[qId] != null && answers[qId]!.trim() == expectedAnswer.toString().trim()) {
        correct++;
      }
    });

    final total = challengeKeyMap.isNotEmpty ? challengeKeyMap.length : answers.length;
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
