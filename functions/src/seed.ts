import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

function isValidDocumentId(value: unknown): value is string {
  return typeof value === "string" && /^[A-Za-z0-9_-]{1,128}$/.test(value);
}

function validateChallengeBanks(
  challenges: Array<Record<string, unknown>>,
  answerKeys: Record<string, unknown>,
) {
  const challengeIds = new Set<string>();
  for (const challenge of challenges) {
    const challengeId = challenge.id;
    const chapterId = challenge.chapterId;
    const languageCode = challenge.languageCode;
    const questions = challenge.questions;
    if (
      !isValidDocumentId(challengeId) ||
      !isValidDocumentId(chapterId) ||
      !["en", "tl", "bik"].includes(String(languageCode)) ||
      challengeIds.has(challengeId) ||
      !Array.isArray(questions) ||
      questions.length === 0
    ) {
      throw new Error("Challenge bank metadata is invalid.");
    }
    challengeIds.add(challengeId);

    const optionIdsByQuestion = new Map<string, Set<string>>();
    const questionIds = questions.map((question) => {
      if (
        question === null ||
        typeof question !== "object" ||
        !isValidDocumentId((question as Record<string, unknown>).id)
      ) {
        throw new Error(`Challenge ${challengeId} contains an invalid question.`);
      }
      const questionData = question as Record<string, unknown>;
      const choices = questionData.choices ?? questionData.options;
      if (!Array.isArray(choices) || choices.length === 0) {
        throw new Error(`Question ${questionData.id} has no choices.`);
      }
      const optionIds = choices.map((choice, index) => {
        if (typeof choice === "string") return String.fromCharCode(97 + index);
        if (
          choice !== null &&
          typeof choice === "object" &&
          typeof (choice as Record<string, unknown>).id === "string"
        ) {
          return (choice as Record<string, unknown>).id as string;
        }
        return "";
      });
      if (optionIds.some((id) => !isValidDocumentId(id))) {
        throw new Error(`Question ${questionData.id} has an invalid choice.`);
      }
      optionIdsByQuestion.set(questionData.id as string, new Set(optionIds));
      return questionData.id as string;
    });
    if (new Set(questionIds).size !== questionIds.length) {
      throw new Error(`Challenge ${challengeId} has duplicate question IDs.`);
    }

    const keys = answerKeys[challengeId];
    if (
      keys === null ||
      typeof keys !== "object" ||
      Array.isArray(keys) ||
      Object.keys(keys).length !== questionIds.length ||
      questionIds.some((questionId) => {
        const answer = (keys as Record<string, unknown>)[questionId];
        return (
          typeof answer !== "string" ||
          !optionIdsByQuestion.get(questionId)?.has(answer)
        );
      })
    ) {
      throw new Error(
        `Challenge ${challengeId} must have one answer key per question.`,
      );
    }
  }

  if (Object.keys(answerKeys).some((id) => !challengeIds.has(id))) {
    throw new Error("Answer keys contain a challenge without a question bank.");
  }
}

async function seed() {
  console.log("Seeding BasaLINO Firestore database...");

  // 1. Stories
  const storiesPath = path.resolve(__dirname, "../../assets/data/stories.json");
  const stories = JSON.parse(fs.readFileSync(storiesPath, "utf-8"));
  for (const s of stories) {
    await db.collection("stories").doc(s.id).set(s);
    console.log(`Seeded story: ${s.id}`);
  }

  // 2. Chapters & Translations
  const chaptersPath = path.resolve(__dirname, "../../assets/data/chapters.json");
  const chapters = JSON.parse(fs.readFileSync(chaptersPath, "utf-8"));
  for (const c of chapters) {
    const { translations, ...chapterMeta } = c;
    await db.collection("chapters").doc(c.id).set(chapterMeta);

    for (const lang of Object.keys(translations)) {
      const transId = `${c.id}_${lang}`;
      await db.collection("chapterTranslations").doc(transId).set({
        chapterId: c.id,
        languageCode: lang,
        ...translations[lang],
      });
    }
    console.log(`Seeded chapter: ${c.id} with translations`);
  }

  // 3. Challenges
  const challengesPath = path.resolve(__dirname, "../../assets/data/challenges.json");
  const challenges = JSON.parse(fs.readFileSync(challengesPath, "utf-8")) as Array<Record<string, unknown>>;
  const keysPath = path.resolve(__dirname, "../../assets/data/challenge_keys.json");
  const keys = JSON.parse(fs.readFileSync(keysPath, "utf-8")) as Record<string, unknown>;
  validateChallengeBanks(challenges, keys);
  for (const ch of challenges) {
    const challengeId = ch.id as string;
    await db.collection("challenges").doc(challengeId).set(ch);
    console.log(`Seeded challenge: ${challengeId}`);
  }

  // 4. Private Challenge Keys
  for (const keyId of Object.keys(keys)) {
    await db.collection("challengeKeys").doc(keyId).set({
      answers: keys[keyId],
    });
    console.log(`Seeded private challenge key: ${keyId}`);
  }

  console.log("Seeding completed successfully!");
}

seed().catch((err) => {
  console.error("Error during seeding:", err);
  process.exit(1);
});
