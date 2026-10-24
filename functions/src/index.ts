import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

interface SubmitAttemptData {
  challengeId: string;
  chapterId: string;
  storyId: string;
  answers: Record<string, string>;
  attemptId: string; // Client idempotency key
}

/**
 * Callable Cloud Function: submitAttempt
 * Validates reading comprehension answers, awards XP, and unlocks the next chapter.
 */
export const submitAttempt = functions.https.onCall(async (data: SubmitAttemptData, context) => {
  // 1. Authenticate caller
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Only authenticated learners can submit comprehension attempts."
    );
  }

  const userId = context.auth.uid;
  const { challengeId, chapterId, storyId, answers, attemptId } = data;

  if (!challengeId || !chapterId || !storyId || !answers || !attemptId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields for attempt submission."
    );
  }

  // 2. Safeguard check: Verify user approval status
  const userDocRef = db.collection("users").doc(userId);
  const userSnap = await userDocRef.get();
  if (!userSnap.exists) {
    throw new functions.https.HttpsError("not-found", "User record does not exist.");
  }

  const userData = userSnap.data()!;
  if (userData.approvalStatus !== "approved") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Account requires parental or guardian approval before submitting challenges."
    );
  }

  // 3. Idempotency Check: Verify if this attemptId was already processed
  const attemptDocRef = db.collection("attempts").doc(attemptId);
  const existingAttempt = await attemptDocRef.get();
  if (existingAttempt.exists) {
    // Return existing calculation without awarding duplicate XP
    const existing = existingAttempt.data()!;
    return {
      attemptId,
      score: existing.score,
      totalQuestions: existing.totalQuestions,
      correctAnswers: existing.correctAnswers,
      xpAwarded: 0, // Duplicate retry awards 0 extra XP
      passed: existing.passed,
      nextChapterId: existing.nextChapterId,
      isDuplicate: true,
    };
  }

  // 4. Retrieve private answer keys from protected server collection
  const keyDoc = await db.collection("challengeKeys").doc(challengeId).get();
  if (!keyDoc.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "Answer key for this challenge could not be found."
    );
  }

  const expectedAnswers = keyDoc.data()!.answers as Record<string, string>;
  const questionIds = Object.keys(expectedAnswers);
  const totalQuestions = questionIds.length;

  let correctCount = 0;
  for (const qId of questionIds) {
    const userAnswer = answers[qId];
    if (userAnswer && userAnswer.trim().toLowerCase() === expectedAnswers[qId].trim().toLowerCase()) {
      correctCount++;
    }
  }

  const score = totalQuestions > 0 ? Math.round((correctCount / totalQuestions) * 100) : 0;
  const passed = score >= 60; // 60% completion threshold

  // 5. XP Award calculation: +10 XP per correct question, +5 XP bonus for 100%
  let xpAwarded = 0;
  if (passed) {
    xpAwarded = correctCount * 10;
    if (score === 100) {
      xpAwarded += 5;
    }
  }

  // 6. Determine next chapter
  let nextChapterId: string | null = null;
  if (passed) {
    if (chapterId === "ibalong_ch1") nextChapterId = "ibalong_ch2";
    else if (chapterId === "ibalong_ch2") nextChapterId = "ibalong_ch3";
    else if (chapterId === "mayon_ch1") nextChapterId = "mayon_ch2";
    else if (chapterId === "mayon_ch2") nextChapterId = "mayon_ch3";
  }

  // 7. Atomic transaction: Record attempt, update user XP, update chapter unlocks
  await db.runTransaction(async (transaction) => {
    // Save attempt audit log
    transaction.set(attemptDocRef, {
      userId,
      storyId,
      chapterId,
      challengeId,
      score,
      totalQuestions,
      correctAnswers: correctCount,
      xpAwarded,
      passed,
      nextChapterId,
      attemptedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update user profile total XP
    if (xpAwarded > 0) {
      transaction.update(userDocRef, {
        totalXp: admin.firestore.FieldValue.increment(xpAwarded),
      });
    }

    // Update story progression subcollection
    const progressRef = db.collection("users").doc(userId).collection("progress").doc(storyId);
    const progressSnap = await transaction.get(progressRef);

    if (passed) {
      if (!progressSnap.exists) {
        transaction.set(progressRef, {
          storyId,
          completedChapterIds: [chapterId],
          currentUnlockedChapterId: nextChapterId || chapterId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        const curData = progressSnap.data()!;
        const completed: string[] = curData.completedChapterIds || [];
        if (!completed.includes(chapterId)) {
          completed.push(chapterId);
        }
        transaction.update(progressRef, {
          completedChapterIds: completed,
          currentUnlockedChapterId: nextChapterId || curData.currentUnlockedChapterId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
  });

  return {
    attemptId,
    score,
    totalQuestions,
    correctAnswers: correctCount,
    xpAwarded,
    passed,
    nextChapterId,
  };
});
