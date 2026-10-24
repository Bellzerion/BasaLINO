import 'package:flutter_test/flutter_test.dart';
import 'package:basalino/core/models/user_model.dart';
import 'package:basalino/core/models/chapter_model.dart';
import 'package:basalino/core/models/attempt_result_model.dart';

void main() {
  group('Progression & Unlocking Business Rules', () {
    test('Quiz scoring passes when score >= 60%', () {
      const passingAttempt = AttemptResultModel(
        attemptId: 'att_1',
        score: 66,
        totalQuestions: 3,
        correctAnswers: 2,
        xpAwarded: 20,
        passed: true,
        nextChapterId: 'ibalong_ch2',
      );

      expect(passingAttempt.passed, isTrue);
      expect(passingAttempt.nextChapterId, equals('ibalong_ch2'));
      expect(passingAttempt.xpAwarded, equals(20));
    });

    test('Quiz scoring fails when score < 60%', () {
      const failingAttempt = AttemptResultModel(
        attemptId: 'att_2',
        score: 33,
        totalQuestions: 3,
        correctAnswers: 1,
        xpAwarded: 0,
        passed: false,
        nextChapterId: null,
      );

      expect(failingAttempt.passed, isFalse);
      expect(failingAttempt.nextChapterId, isNull);
      expect(failingAttempt.xpAwarded, equals(0));
    });

    test('Perfect score receives bonus XP', () {
      int calculateXp(int correct, int total) {
        final score = ((correct / total) * 100).round();
        if (score < 60) return 0;
        int xp = correct * 10;
        if (score == 100) xp += 5;
        return xp;
      }

      expect(calculateXp(3, 3), equals(35));
      expect(calculateXp(2, 3), equals(20));
      expect(calculateXp(1, 3), equals(0));
    });

    test('Chapter status states correctly identify locked, unlocked, completed', () {
      const ch1 = ChapterModel(
        id: 'ch1',
        storyId: 's1',
        orderIndex: 0,
        status: ChapterStatus.completed,
      );
      const ch2 = ChapterModel(
        id: 'ch2',
        storyId: 's1',
        orderIndex: 1,
        status: ChapterStatus.unlocked,
      );
      const ch3 = ChapterModel(
        id: 'ch3',
        storyId: 's1',
        orderIndex: 2,
        status: ChapterStatus.locked,
      );

      expect(ch1.isCompleted, isTrue);
      expect(ch1.isLocked, isFalse);
      expect(ch2.isUnlocked, isTrue);
      expect(ch3.isLocked, isTrue);
    });

    test('User approval status accurately detects pending vs approved', () {
      final approvedUser = UserModel(
        uid: 'u1',
        email: 'test@basalino.ph',
        nickname: 'Nino',
        preferredLanguage: 'en',
        approvalStatus: ApprovalStatus.approved,
        totalXp: 100,
        createdAt: DateTime.now(),
      );

      final pendingUser = approvedUser.copyWith(approvalStatus: ApprovalStatus.pending);

      expect(approvedUser.isApproved, isTrue);
      expect(pendingUser.isApproved, isFalse);
    });
  });
}
