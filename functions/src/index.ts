import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import * as functions from "firebase-functions/v1";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const supportedLanguages = new Set(["en", "tl", "bik"]);
const allowedProfileFields = new Set([
  "uid",
  "email",
  "createdAt",
  "approvalStatus",
  "preferredLanguage",
  "displayName",
  "nickname",
  "totalXp",
]);
const projectionVersion = 1;
const maxAttemptQuestions = 5;

interface SubmitAttemptData {
  challengeId?: unknown;
  chapterId?: unknown;
  storyId?: unknown;
  questionIds?: unknown;
  answers?: unknown;
  attemptId?: unknown;
}

interface AwardVocabularyBonusData {
  chapterId?: unknown;
}

interface ChallengeQuestion {
  id: string;
  options: string[];
}

interface ProgressProjection {
  storyId: string;
  completedChapterIds: string[];
  nextUnlockedChapter: string | null;
  storyCompleted: boolean;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isDocumentId(value: unknown): value is string {
  return (
    typeof value === "string" &&
    /^[A-Za-z0-9_-]{1,128}$/.test(value)
  );
}

function invalidArgument(message: string): never {
  throw new functions.https.HttpsError("invalid-argument", message);
}

function validateProfile(
  profile: admin.firestore.DocumentData | undefined,
  uid: string,
): asserts profile is admin.firestore.DocumentData {
  if (!profile) {
    throw new functions.https.HttpsError("not-found", "User profile does not exist.");
  }

  const hasOnlyKnownFields = Object.keys(profile).every((key) =>
    allowedProfileFields.has(key),
  );
  const validDisplayName =
    profile.displayName === undefined ||
    (typeof profile.displayName === "string" &&
      profile.displayName.length > 0 &&
      profile.displayName.length <= 80);
  const validLegacyNickname =
    profile.nickname === undefined ||
    (typeof profile.nickname === "string" &&
      profile.nickname.length > 0 &&
      profile.nickname.length <= 80);
  const validXp =
    profile.totalXp === undefined ||
    (Number.isSafeInteger(profile.totalXp) && profile.totalXp >= 0);

  if (
    !hasOnlyKnownFields ||
    profile.uid !== uid ||
    typeof profile.email !== "string" ||
    !(profile.createdAt instanceof Timestamp) ||
    !supportedLanguages.has(profile.preferredLanguage) ||
    !validDisplayName ||
    !validLegacyNickname ||
    (profile.displayName !== undefined && profile.nickname !== undefined) ||
    !validXp ||
    !["pending", "approved", "rejected"].includes(profile.approvalStatus)
  ) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "User profile does not match the supported profile contract.",
    );
  }
  if (profile.approvalStatus !== "approved") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Account requires guardian approval before progression can be updated.",
    );
  }
}

function readChallengeQuestions(value: unknown): ChallengeQuestion[] | null {
  if (!Array.isArray(value) || value.length === 0) return null;
  const questions: ChallengeQuestion[] = [];
  const ids = new Set<string>();

  for (const rawQuestion of value) {
    if (!isRecord(rawQuestion) || !isDocumentId(rawQuestion.id)) return null;
    if (ids.has(rawQuestion.id)) return null;
    ids.add(rawQuestion.id);

    const rawOptions = rawQuestion.options ?? rawQuestion.choices;
    if (!Array.isArray(rawOptions) || rawOptions.length === 0) return null;
    const options = rawOptions.map((option, index) => {
      if (typeof option === "string") {
        return String.fromCharCode(97 + index);
      }
      if (isRecord(option) && typeof option.id === "string") {
        return option.id;
      }
      return "";
    });
    if (options.some((option) => option.length === 0)) return null;
    questions.push({ id: rawQuestion.id, options });
  }
  return questions;
}

function projectProgress(
  storyId: string,
  chapters: FirebaseFirestore.QueryDocumentSnapshot[],
  completedChapterIds: Set<string>,
): ProgressProjection {
  const orderedChapters = chapters
    .map((chapter) => ({
      id: chapter.id,
      orderIndex: chapter.get("orderIndex"),
    }))
    .sort((left, right) => left.orderIndex - right.orderIndex);

  if (
    orderedChapters.length === 0 ||
    orderedChapters.some(
      (chapter) => !Number.isInteger(chapter.orderIndex),
    ) ||
    new Set(orderedChapters.map((chapter) => chapter.orderIndex)).size !==
      orderedChapters.length
  ) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Story chapter metadata is invalid.",
    );
  }

  const chapterIds = orderedChapters.map((chapter) => chapter.id);
  const knownChapterIds = new Set(chapterIds);
  if ([...completedChapterIds].some((id) => !knownChapterIds.has(id))) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Stored progress contains a chapter outside this story.",
    );
  }

  return {
    storyId,
    completedChapterIds: chapterIds.filter((id) => completedChapterIds.has(id)),
    nextUnlockedChapter:
      chapterIds.find((id) => !completedChapterIds.has(id)) ?? null,
    storyCompleted: chapterIds.every((id) => completedChapterIds.has(id)),
  };
}

function readCompletedChapterIds(
  progress: admin.firestore.DocumentData | undefined,
  storyId: string,
): Set<string> {
  if (!progress) return new Set();
  const value = progress.completedChapterIds;
  const version = progress.projectionVersion;
  if (
    progress.storyId !== storyId ||
    !Array.isArray(value) ||
    value.some((chapterId) => !isDocumentId(chapterId)) ||
    (version !== undefined &&
      (typeof version !== "number" ||
        !Number.isInteger(version) ||
        version < 0 ||
        version > projectionVersion))
  ) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Stored story progress does not match the supported projection contract.",
    );
  }
  return new Set(value);
}

/**
 * Grades a selected subset of a seeded challenge bank (up to five questions).
 * Attempt creation, XP award, and progress projection update are atomic.
 */
export const submitAttempt = functions.https.onCall(
  async (data: SubmitAttemptData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Only authenticated learners can submit comprehension attempts.",
      );
    }

    if (
      !isRecord(data) ||
      !isDocumentId(data.challengeId) ||
      !isDocumentId(data.chapterId) ||
      !isDocumentId(data.storyId) ||
      !isDocumentId(data.attemptId) ||
      !Array.isArray(data.questionIds) ||
      data.questionIds.length === 0 ||
      data.questionIds.length > maxAttemptQuestions ||
      data.questionIds.some((id) => !isDocumentId(id)) ||
      !isRecord(data.answers)
    ) {
      invalidArgument("Attempt data is invalid.");
    }

    const { challengeId, chapterId, storyId, attemptId } = data as {
      challengeId: string;
      chapterId: string;
      storyId: string;
      attemptId: string;
    };
    const questionIds = data.questionIds as string[];
    const answers = data.answers as Record<string, unknown>;
    if (
      new Set(questionIds).size !== questionIds.length ||
      Object.keys(answers).length !== questionIds.length ||
      questionIds.some(
        (id) => typeof answers[id] !== "string" || answers[id].length === 0,
      ) ||
      Object.keys(answers).some((id) => !questionIds.includes(id))
    ) {
      invalidArgument("Attempt answers must match the selected question IDs.");
    }

    const userId = context.auth.uid;
    const userRef = db.collection("users").doc(userId);
    const attemptRef = db.collection("attempts").doc(attemptId);
    const challengeRef = db.collection("challenges").doc(challengeId);
    const keyRef = db.collection("challengeKeys").doc(challengeId);
    const chapterRef = db.collection("chapters").doc(chapterId);
    const progressRef = userRef.collection("progress").doc(storyId);
    const chaptersQuery = db
      .collection("chapters")
      .where("storyId", "==", storyId);

    return db.runTransaction(async (transaction) => {
      const previousAttempt = await transaction.get(attemptRef);
      if (previousAttempt.exists) {
        const previous = previousAttempt.data()!;
        if (previous.userId !== userId) {
          throw new functions.https.HttpsError(
            "permission-denied",
            "Attempt ID is already owned by another user.",
          );
        }
        return {
          attemptId,
          score: previous.score,
          totalQuestions: previous.totalQuestions,
          correctAnswers: previous.correctAnswers,
          xpAwarded: 0,
          passed: previous.passed,
          nextChapterId: previous.nextChapterId ?? null,
          nextUnlockedChapter: previous.nextUnlockedChapter ?? null,
          storyCompleted: previous.storyCompleted ?? false,
          isDuplicate: true,
        };
      }

      const [
        userSnapshot,
        challengeSnapshot,
        keySnapshot,
        chapterSnapshot,
        progressSnapshot,
        chaptersSnapshot,
      ] = await Promise.all([
        transaction.get(userRef),
        transaction.get(challengeRef),
        transaction.get(keyRef),
        transaction.get(chapterRef),
        transaction.get(progressRef),
        transaction.get(chaptersQuery),
      ]);

      validateProfile(userSnapshot.data(), userId);
      if (!challengeSnapshot.exists || !keySnapshot.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Challenge bank or answer key could not be found.",
        );
      }
      if (
        !chapterSnapshot.exists ||
        chapterSnapshot.get("storyId") !== storyId
      ) {
        invalidArgument("Chapter does not belong to the requested story.");
      }
      if (
        challengeSnapshot.get("chapterId") !== chapterId ||
        !["en", "tl", "bik"].includes(challengeSnapshot.get("languageCode"))
      ) {
        invalidArgument("Challenge bank does not match the requested chapter.");
      }

      const bankQuestions = readChallengeQuestions(
        challengeSnapshot.get("questions"),
      );
      const questionById = new Map(
        (bankQuestions ?? []).map((question) => [question.id, question]),
      );
      const expectedAnswers = keySnapshot.get("answers");
      if (
        bankQuestions === null ||
        !isRecord(expectedAnswers) ||
        questionIds.some((id) => {
          const question = questionById.get(id);
          const expected = expectedAnswers[id];
          return (
            !question ||
            typeof expected !== "string" ||
            !question.options.includes(expected)
          );
        })
      ) {
        invalidArgument("Attempt contains a question outside the challenge bank.");
      }

      const chapters = chaptersSnapshot.docs;
      if (!chapters.some((chapter) => chapter.id === chapterId)) {
        invalidArgument("Chapter metadata is not part of the requested story.");
      }

      let correctAnswers = 0;
      for (const questionId of questionIds) {
        if (answers[questionId] === expectedAnswers[questionId]) {
          correctAnswers++;
        }
      }
      const totalQuestions = questionIds.length;
      const score = Math.round((correctAnswers / totalQuestions) * 100);
      const passed = score >= 60;
      const xpAwarded = passed
        ? correctAnswers * 10 + (score === 100 ? 5 : 0)
        : 0;

      const completedChapterIds = readCompletedChapterIds(
        progressSnapshot.data(),
        storyId,
      );
      if (passed) completedChapterIds.add(chapterId);
      const projection = projectProgress(
        storyId,
        chapters,
        completedChapterIds,
      );

      transaction.create(attemptRef, {
        userId,
        storyId,
        chapterId,
        challengeId,
        questionIds,
        score,
        totalQuestions,
        correctAnswers,
        xpAwarded,
        passed,
        nextChapterId: projection.nextUnlockedChapter,
        nextUnlockedChapter: projection.nextUnlockedChapter,
        storyCompleted: projection.storyCompleted,
        attemptedAt: FieldValue.serverTimestamp(),
      });

      if (xpAwarded > 0) {
        transaction.update(userRef, {
          totalXp: FieldValue.increment(xpAwarded),
        });
      }
      if (passed) {
        transaction.set(progressRef, {
          storyId: projection.storyId,
          completedChapterIds: projection.completedChapterIds,
          updatedAt: FieldValue.serverTimestamp(),
          projectionVersion,
        });
      }

      return {
        attemptId,
        score,
        totalQuestions,
        correctAnswers,
        xpAwarded,
        passed,
        nextChapterId: projection.nextUnlockedChapter,
        nextUnlockedChapter: projection.nextUnlockedChapter,
        storyCompleted: projection.storyCompleted,
        isDuplicate: false,
      };
    });
  },
);

/**
 * Awards a one-time vocabulary bonus after the chapter has been passed.
 */
export const awardVocabularyBonus = functions.https.onCall(
  async (data: AwardVocabularyBonusData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Only authenticated learners can earn vocabulary bonus XP.",
      );
    }
    if (!isRecord(data) || !isDocumentId(data.chapterId)) {
      invalidArgument("A valid chapter ID is required.");
    }

    const chapterId = data.chapterId as string;
    const userId = context.auth.uid;
    const userRef = db.collection("users").doc(userId);
    const bonusRef = userRef.collection("vocabularyBonuses").doc(chapterId);
    const chapterRef = db.collection("chapters").doc(chapterId);

    return db.runTransaction(async (transaction) => {
      const bonusSnapshot = await transaction.get(bonusRef);
      if (bonusSnapshot.exists) {
        return { awarded: false, xpAwarded: 0, isDuplicate: true };
      }

      const [userSnapshot, chapterSnapshot] = await Promise.all([
        transaction.get(userRef),
        transaction.get(chapterRef),
      ]);
      validateProfile(userSnapshot.data(), userId);
      if (!chapterSnapshot.exists || !isDocumentId(chapterSnapshot.get("storyId"))) {
        throw new functions.https.HttpsError(
          "not-found",
          "Chapter metadata could not be found.",
        );
      }
      const storyId = chapterSnapshot.get("storyId") as string;
      const progressRef = userRef.collection("progress").doc(storyId);
      const progressSnapshot = await transaction.get(progressRef);
      const completedChapterIds = readCompletedChapterIds(
        progressSnapshot.data(),
        storyId,
      );
      if (!completedChapterIds.has(chapterId)) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "The chapter quiz must be passed before claiming vocabulary bonus XP.",
        );
      }

      const xpAwarded = 5;
      transaction.update(userRef, {
        totalXp: FieldValue.increment(xpAwarded),
      });
      transaction.create(bonusRef, {
        chapterId,
        xpAwarded,
        awardedAt: FieldValue.serverTimestamp(),
      });
      return { awarded: true, xpAwarded, isDuplicate: false };
    });
  },
);
