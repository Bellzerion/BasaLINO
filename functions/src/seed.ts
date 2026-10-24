import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

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
  const challenges = JSON.parse(fs.readFileSync(challengesPath, "utf-8"));
  for (const ch of challenges) {
    await db.collection("challenges").doc(ch.id).set(ch);
    console.log(`Seeded challenge: ${ch.id}`);
  }

  // 4. Private Challenge Keys
  const keysPath = path.resolve(__dirname, "../../assets/data/challenge_keys.json");
  const keys = JSON.parse(fs.readFileSync(keysPath, "utf-8"));
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
