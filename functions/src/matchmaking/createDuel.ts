import { HttpsError } from "firebase-functions/v2/https";
import { db, FieldValue, Timestamp } from "../lib/admin";
import { DUEL_INTRO_SECONDS, ROUNDS_PER_DUEL } from "../lib/constants";
import { RoundDoc } from "../lib/types";
import { pickNextQuestion } from "../scoring/resolveDuel";

/**
 * Shared internal helper that actually creates a duel + its first round.
 * Called from both `matchmaking/duelChallenges.ts` (a direct challenge got
 * accepted) and `matchmaking/openLobby.ts` (quick match found an
 * opponent) — neither of those files talks to the `duels` collection
 * directly, so this is the one place a duel comes into existence.
 */
export async function createDuelForPlayers(player1Id: string, player2Id: string, categoryId: string): Promise<string> {
  const [categorySnap, player1Snap, player2Snap] = await Promise.all([
    db.collection("categories").doc(categoryId).get(),
    db.collection("users").doc(player1Id).get(),
    db.collection("users").doc(player2Id).get(),
  ]);

  if (!categorySnap.exists) throw new HttpsError("not-found", "Category not found.");
  const category = categorySnap.data()!;

  // The duel's language is fixed for its whole lifetime from whoever
  // started it (player1), so both rounds are always in one language rather
  // than flipping mid-duel if the two players have different preferences.
  const language: string = player1Snap.data()?.locale ?? "en";

  const firstQuestion = await pickNextQuestion(categoryId, language, []);
  if (!firstQuestion) {
    throw new HttpsError("failed-precondition", "This category has no questions yet.");
  }

  // Snapshotted once here (rather than re-derived from `categoryId` on
  // every read) so it survives the category being renamed/deleted later —
  // picked in the same language the duel's questions are in, so the
  // category label and questions never mismatch languages.
  const categoryName: string = language === "en" && category.nameEn ? category.nameEn : category.name;

  const duelRef = db.collection("duels").doc();
  await duelRef.set({
    player1Id,
    player2Id,
    participantIds: [player1Id, player2Id],
    player1DisplayName: player1Snap.data()?.displayName ?? "",
    player2DisplayName: player2Snap.data()?.displayName ?? "",
    categoryId,
    categoryName,
    language,
    isHomeTurfDuel: category.ownerId != null,
    homeTurfOwnerId: category.ownerId ?? null,
    status: "active",
    player1Score: 0,
    player2Score: 0,
    currentRound: 1,
    totalRounds: ROUNDS_PER_DUEL,
    usedQuestionIds: [firstQuestion.id],
    winnerId: null,
    eloChange: {},
    createdAt: FieldValue.serverTimestamp(),
    startedAt: FieldValue.serverTimestamp(),
    completedAt: null,
  });

  await duelRef.collection("rounds").doc("1").set({
    roundNumber: 1,
    questionId: firstQuestion.id,
    questionText: firstQuestion.data.questionText,
    options: firstQuestion.data.options,
    difficulty: firstQuestion.data.difficulty,
    status: "active",
    correctAnswerIndex: null,
    playerAnswers: {},
    pointsAwarded: {},
    // Deliberately not `serverTimestamp()` (i.e. "now") — every client
    // spends the next `DUEL_INTRO_SECONDS` on the VS intro screen before it
    // ever shows this round, so starting the clock "now" would burn most of
    // round 1's answer window before either player can even see the
    // question. Every later round's `startedAt` (set in resolveDuel.ts) IS
    // "now", since there's no intro screen between rounds 2-5 — this is
    // round 1 alone catching up to that same guarantee.
    startedAt: Timestamp.fromMillis(Date.now() + DUEL_INTRO_SECONDS * 1000),
  } satisfies Partial<RoundDoc>);

  return duelRef.id;
}
