import { HttpsError, onCall } from "firebase-functions/v2/https";
import { db, FieldValue } from "../lib/admin";
import { MAX_HOME_TURF_CATEGORIES } from "../lib/constants";
import { QuestionDifficulty, UserDoc } from "../lib/types";

const VALID_DIFFICULTIES: QuestionDifficulty[] = ["easy", "medium", "hard"];

/**
 * Creates a home-turf category owned by the caller, enforcing the
 * `MAX_HOME_TURF_CATEGORIES` cap server-side (the client also disables the
 * "new category" button at 3 for a nicer UX, but this is the actual guard —
 * see `firestore.rules`, which blocks clients from writing `categories`
 * directly for the same reason).
 */
export const createHomeTurfCategory = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");

  const { name, description } = request.data as { name?: unknown; description?: unknown };
  if (typeof name !== "string" || name.trim().length === 0 || name.trim().length > 30) {
    throw new HttpsError("invalid-argument", "name must be 1-30 characters.");
  }
  const trimmedDescription = typeof description === "string" ? description.trim().slice(0, 120) : "";

  const categoryId = await db.runTransaction(async (tx) => {
    const userRef = db.collection("users").doc(uid);
    const userSnap = await tx.get(userRef);
    const user = userSnap.data() as UserDoc | undefined;
    const ownedCount = user?.ownedCategoryIds?.length ?? 0;

    if (ownedCount >= MAX_HOME_TURF_CATEGORIES) {
      throw new HttpsError("resource-exhausted", `You already own ${MAX_HOME_TURF_CATEGORIES} categories.`);
    }

    const categoryRef = db.collection("categories").doc();
    tx.set(categoryRef, {
      name: name.trim(),
      description: trimmedDescription,
      ownerId: uid,
      ownerDisplayName: user?.displayName ?? "",
      groupId: null, // groups are only for the seeded system taxonomy — see seed/categoryTaxonomy.ts
      questionCount: 0,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(userRef, { ownedCategoryIds: FieldValue.arrayUnion(categoryRef.id) });

    return categoryRef.id;
  });

  return { categoryId };
});

/** Adds a single hand-written question to a category the caller owns. */
export const addHomeTurfQuestion = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");

  const { categoryId, questionText, options, correctAnswerIndex, difficulty } = request.data as {
    categoryId?: unknown;
    questionText?: unknown;
    options?: unknown;
    correctAnswerIndex?: unknown;
    difficulty?: unknown;
  };

  if (typeof categoryId !== "string" || categoryId.length === 0) {
    throw new HttpsError("invalid-argument", "categoryId is required.");
  }
  if (typeof questionText !== "string" || questionText.trim().length === 0) {
    throw new HttpsError("invalid-argument", "questionText is required.");
  }
  if (!Array.isArray(options) || options.length !== 4 || !options.every((o) => typeof o === "string" && o.trim())) {
    throw new HttpsError("invalid-argument", "options must contain exactly 4 non-empty strings.");
  }
  if (
    typeof correctAnswerIndex !== "number" ||
    !Number.isInteger(correctAnswerIndex) ||
    correctAnswerIndex < 0 ||
    correctAnswerIndex > 3
  ) {
    throw new HttpsError("invalid-argument", "correctAnswerIndex must be 0-3.");
  }
  if (typeof difficulty !== "string" || !VALID_DIFFICULTIES.includes(difficulty as QuestionDifficulty)) {
    throw new HttpsError("invalid-argument", "difficulty must be easy, medium, or hard.");
  }

  const categoryRef = db.collection("categories").doc(categoryId);
  const [categorySnap, userSnap] = await Promise.all([categoryRef.get(), db.collection("users").doc(uid).get()]);
  if (!categorySnap.exists) throw new HttpsError("not-found", "Category not found.");
  if (categorySnap.data()?.ownerId !== uid) {
    throw new HttpsError("permission-denied", "You can only add questions to your own category.");
  }
  // Tags the question in whatever language its author actually writes in,
  // same as `createDuel.ts` does for a duel's question language — rather
  // than a fixed default that would mislabel every home-turf question
  // written by a player whose profile isn't in that language.
  const language = (userSnap.data() as UserDoc | undefined)?.locale ?? "en";

  const batch = db.batch();
  batch.set(db.collection("questions").doc(), {
    categoryId,
    ownerId: uid,
    questionText: questionText.trim(),
    options: options.map((o) => (o as string).trim()),
    correctAnswerIndex,
    difficulty,
    source: "user",
    language,
    createdAt: FieldValue.serverTimestamp(),
  });
  batch.update(categoryRef, { questionCount: FieldValue.increment(1) });
  await batch.commit();

  return { success: true };
});
