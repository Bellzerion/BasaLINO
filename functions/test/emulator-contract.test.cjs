const assert = require("node:assert/strict");
const { randomUUID } = require("node:crypto");
const { after, test } = require("node:test");
const admin = require("firebase-admin");

const projectId = process.env.GCLOUD_PROJECT || "demo-basalino";
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
const functionsHost = "127.0.0.1:5001";
const database = `(default)`;

assert.ok(process.env.FIREBASE_AUTH_EMULATOR_HOST, "Run this suite with the Auth emulator.");
assert.ok(process.env.FIRESTORE_EMULATOR_HOST, "Run this suite with the Firestore emulator.");

if (admin.apps.length === 0) {
  admin.initializeApp({ projectId });
}
const adminDb = admin.firestore();

async function postJson(url, body, headers = {}) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json", ...headers },
    body: JSON.stringify(body),
  });
  const responseBody = await response.json().catch(() => ({}));
  return { status: response.status, body: responseBody };
}

async function createAuthUser(email) {
  const result = await postJson(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator-key`,
    { email, password: "contract-test-password", returnSecureToken: true },
  );
  assert.equal(result.status, 200, JSON.stringify(result.body));
  return { uid: result.body.localId, token: result.body.idToken, email };
}

function firestoreDocumentUrl(path) {
  return `http://${firestoreHost}/v1/projects/${projectId}/databases/${database}/documents/${path}`;
}

function firestoreFields(fields) {
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => {
      if (typeof value === "string") return [key, { stringValue: value }];
      if (typeof value === "number") return [key, { integerValue: String(value) }];
      if (typeof value === "boolean") return [key, { booleanValue: value }];
      return [key, value];
    }),
  );
}

async function createClientProfile(user, fields) {
  const name = `projects/${projectId}/databases/${database}/documents/users/${user.uid}`;
  return postJson(
    `http://${firestoreHost}/v1/projects/${projectId}/databases/${database}/documents:commit`,
    {
      writes: [
        {
          update: { name, fields: firestoreFields(fields) },
          updateTransforms: [
            { fieldPath: "createdAt", setToServerValue: "REQUEST_TIME" },
          ],
          currentDocument: { exists: false },
        },
      ],
    },
    { authorization: `Bearer ${user.token}` },
  );
}

async function readAsUser(path, user) {
  const response = await fetch(firestoreDocumentUrl(path), {
    headers: { authorization: `Bearer ${user.token}` },
  });
  return { status: response.status, body: await response.json().catch(() => ({})) };
}

async function submit(user, data) {
  return postJson(
    `http://${functionsHost}/${projectId}/us-central1/submitAttempt`,
    { data },
    { authorization: `Bearer ${user.token}` },
  );
}

async function awardBonus(user, chapterId) {
  return postJson(
    `http://${functionsHost}/${projectId}/us-central1/awardVocabularyBonus`,
    { data: { chapterId } },
    { authorization: `Bearer ${user.token}` },
  );
}

function callableResult(response) {
  if (response.body.error) {
    return { error: response.body.error };
  }
  return response.body.result;
}

function expectCallableError(response, status) {
  assert.ok(response.status >= 400, JSON.stringify(response.body));
  const error = response.body.error;
  assert.ok(error, JSON.stringify(response.body));
  assert.equal(error.status, status);
}

test("profile, ownership, bank, projection and idempotency contracts", async () => {
  const owner = await createAuthUser(`owner-${randomUUID()}@example.test`);
  const other = await createAuthUser(`other-${randomUUID()}@example.test`);
  const approvalMutation = await createAuthUser(
    `approval-${randomUUID()}@example.test`,
  );
  const xpMutation = await createAuthUser(`xp-${randomUUID()}@example.test`);

  const validProfile = await createClientProfile(owner, {
    uid: owner.uid,
    email: owner.email,
    preferredLanguage: "en",
    approvalStatus: "pending",
    displayName: "Contract learner",
  });
  assert.equal(validProfile.status, 200, JSON.stringify(validProfile.body));

  const pendingProfile = await createClientProfile(other, {
    uid: other.uid,
    email: other.email,
    preferredLanguage: "en",
    approvalStatus: "pending",
  });
  assert.equal(pendingProfile.status, 200, JSON.stringify(pendingProfile.body));

  const rejectedApproval = await createClientProfile(approvalMutation, {
    uid: approvalMutation.uid,
    email: approvalMutation.email,
    preferredLanguage: "en",
    approvalStatus: "approved",
  });
  assert.ok(rejectedApproval.status >= 400);

  const rejectedXpField = await createClientProfile(xpMutation, {
    uid: xpMutation.uid,
    email: xpMutation.email,
    preferredLanguage: "en",
    approvalStatus: "pending",
    totalXp: 10,
  });
  assert.ok(rejectedXpField.status >= 400);

  const ownerProfile = await readAsUser(`users/${owner.uid}`, owner);
  assert.equal(ownerProfile.status, 200);
  const foreignProfile = await readAsUser(`users/${owner.uid}`, other);
  assert.ok(foreignProfile.status >= 400);

  const storyId = `contract-story-${randomUUID()}`;
  const chapterOne = `${storyId}_ch1`;
  const chapterTwo = `${storyId}_ch2`;
  const challengeId = `contract-bank-${randomUUID()}`;
  const secondChallengeId = `contract-bank-${randomUUID()}`;
  const attemptId = `contract-attempt-${randomUUID()}`;

  await adminDb.collection("users").doc(owner.uid).update({
    approvalStatus: "approved",
  });
  await adminDb.collection("chapters").doc(chapterOne).set({
    storyId,
    orderIndex: 0,
  });
  await adminDb.collection("chapters").doc(chapterTwo).set({
    storyId,
    orderIndex: 1,
  });
  await adminDb.collection("challenges").doc(challengeId).set({
    chapterId: chapterOne,
    languageCode: "en",
    questions: [
      { id: "q1", choices: ["A", "B", "C", "D"] },
      { id: "q2", choices: ["A", "B", "C", "D"] },
      { id: "q3", choices: ["A", "B", "C", "D"] },
    ],
  });
  await adminDb.collection("challengeKeys").doc(challengeId).set({
    answers: { q1: "b", q2: "b", q3: "b" },
  });
  await adminDb.collection("challenges").doc(secondChallengeId).set({
    chapterId: chapterTwo,
    languageCode: "en",
    questions: [
      { id: "q1", choices: ["A", "B", "C", "D"] },
      { id: "q2", choices: ["A", "B", "C", "D"] },
      { id: "q3", choices: ["A", "B", "C", "D"] },
    ],
  });
  await adminDb.collection("challengeKeys").doc(secondChallengeId).set({
    answers: { q1: "b", q2: "b", q3: "b" },
  });

  const attemptData = {
    challengeId,
    chapterId: chapterOne,
    storyId,
    questionIds: ["q1", "q2", "q3"],
    answers: { q1: "b", q2: "b", q3: "b" },
    attemptId,
  };
  const pendingAttempt = await submit(other, {
    ...attemptData,
    attemptId: `${attemptId}-pending`,
  });
  expectCallableError(pendingAttempt, "PERMISSION_DENIED");

  const invalidQuestion = await submit(owner, {
    ...attemptData,
    attemptId: `${attemptId}-invalid`,
    questionIds: ["not-in-bank"],
    answers: { "not-in-bank": "b" },
  });
  expectCallableError(invalidQuestion, "INVALID_ARGUMENT");

  const firstResults = await Promise.all([
    submit(owner, attemptData),
    submit(owner, attemptData),
  ]);
  for (const result of firstResults) {
    assert.equal(result.status, 200, JSON.stringify(result.body));
  }
  const results = firstResults.map(callableResult);
  assert.equal(results.filter((result) => result.isDuplicate).length, 1);
  assert.equal(results.find((result) => !result.isDuplicate).xpAwarded, 35);
  assert.equal(results.find((result) => !result.isDuplicate).totalQuestions, 3);
  assert.equal(results.find((result) => !result.isDuplicate).nextUnlockedChapter, chapterTwo);
  assert.equal(results.find((result) => !result.isDuplicate).storyCompleted, false);

  const crossOwnerReplay = await submit(other, attemptData);
  expectCallableError(crossOwnerReplay, "PERMISSION_DENIED");

  const progressRef = adminDb
    .collection("users")
    .doc(owner.uid)
    .collection("progress")
    .doc(storyId);
  const projection = (await progressRef.get()).data();
  assert.deepEqual(Object.keys(projection).sort(), [
    "completedChapterIds",
    "projectionVersion",
    "storyId",
    "updatedAt",
  ]);
  assert.deepEqual(projection.completedChapterIds, [chapterOne]);
  assert.equal(projection.projectionVersion, 1);
  assert.equal((await adminDb.collection("attempts").doc(attemptId).get()).exists, true);

  const ownerProgress = await readAsUser(`users/${owner.uid}/progress/${storyId}`, owner);
  assert.equal(ownerProgress.status, 200);
  const foreignProgress = await readAsUser(`users/${owner.uid}/progress/${storyId}`, other);
  assert.ok(foreignProgress.status >= 400);
  const rootProgress = await readAsUser(`progress/${owner.uid}`, owner);
  assert.ok(rootProgress.status >= 400);

  const clientProgressWrite = await fetch(
    firestoreDocumentUrl(`users/${owner.uid}/progress/${storyId}`),
    {
      method: "PATCH",
      headers: {
        authorization: `Bearer ${owner.token}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({ fields: firestoreFields({ storyId }) }),
    },
  );
  assert.ok(clientProgressWrite.status >= 400);

  const secondAttempt = await submit(owner, {
    ...attemptData,
    challengeId: secondChallengeId,
    chapterId: chapterTwo,
    attemptId: `${attemptId}-second`,
  });
  assert.equal(secondAttempt.status, 200, JSON.stringify(secondAttempt.body));
  const secondResult = callableResult(secondAttempt);
  assert.equal(secondResult.storyCompleted, true);
  assert.equal(secondResult.nextUnlockedChapter, null);
  const completeProjection = (await progressRef.get()).data();
  assert.deepEqual(completeProjection.completedChapterIds, [chapterOne, chapterTwo]);
  assert.equal("storyCompleted" in completeProjection, false);
  assert.equal("nextUnlockedChapter" in completeProjection, false);

  const bonusResults = await Promise.all([
    awardBonus(owner, chapterTwo),
    awardBonus(owner, chapterTwo),
  ]);
  for (const result of bonusResults) {
    assert.equal(result.status, 200, JSON.stringify(result.body));
  }
  assert.equal(
    bonusResults.map(callableResult).filter((result) => result.awarded).length,
    1,
  );
  assert.equal(
    (await adminDb.collection("users").doc(owner.uid).get()).get("totalXp"),
    75,
  );
  assert.equal(
    (
      await adminDb
        .collection("users")
        .doc(owner.uid)
        .collection("vocabularyBonuses")
        .doc(chapterTwo)
        .get()
    ).exists,
    true,
  );
});

after(async () => {
  await admin.app().delete();
});
