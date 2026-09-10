import { HttpsError } from "firebase-functions/v2/https";
import { db, FieldValue, Timestamp } from "../lib/admin";
import {
  BASE_POINTS_CORRECT,
  HOME_TURF_MULTIPLIER,
  MAX_SPEED_BONUS,
  ROUND_TIME_LIMIT_SECONDS,
} from "../lib/constants";
import { DuelDoc, QuestionDoc, RoundDoc } from "../lib/types";
import { eloDelta } from "./eloCalculator";

/**
 * THE single source of truth for duel scoring, round resolution, and ELO
 * updates. If you're debugging "why did I get the wrong number of
 * points" or "why didn't my rating change", this is the only file you
 * should need to read.
 *
 * Both `submitAnswer.ts` (a player answered in time) and
 * `expireStaleRounds.ts` (nobody answered in time) end up calling
 * `resolveRoundInTransaction` below with a map of whatever answers exist
 * for the round — a real one has a real `selectedIndex`; a missing one is
 * synthesized as `selectedIndex: -1` (always wrong, zero points). That's
 * the only difference between "someone lost on time" and "someone
 * answered wrong" from this function's point of view.
 */

interface AnswerInput {
  uid: string;
  selectedIndex: number; // -1 means "no answer / timed out"
  answeredAt: FirebaseFirestore.Timestamp;
}

/**
 * Records that `uid` answered round `roundNumber` of `duelId` with
 * `selectedIndex`, and resolves the round the moment both players have
 * answered. Called by the `submitAnswer` callable — see that file for the
 * caller-facing validation (auth, is-it-your-duel, etc.).
 *
 * Throws `HttpsError('already-exists', ...)` if this player already
 * answered this round, and `HttpsError('failed-precondition', ...)` if the
 * round isn't currently open for answers.
 */
export async function recordAnswerAndMaybeResolve(
  duelId: string,
  roundNumber: number,
  uid: string,
  selectedIndex: number,
): Promise<void> {
  const answeredAt = Timestamp.now();
  const duelRef = db.collection("duels").doc(duelId);
  const roundRef = duelRef.collection("rounds").doc(String(roundNumber));
  const answersRef = roundRef.collection("answers");

  // Step 1: record this player's answer. This transaction ONLY writes the
  // answer doc and reports back whether both players have now answered —
  // it must not throw on the "both answered" case, since throwing out of
  // `runTransaction` rolls back everything written inside it (including
  // the answer we just recorded). Actual validation failures below SHOULD
  // roll back, which is why those still throw.
  const result = await db.runTransaction(async (tx) => {
    const [duelSnap, roundSnap, answersSnap] = await Promise.all([
      tx.get(duelRef),
      tx.get(roundRef),
      tx.get(answersRef),
    ]);

    if (!duelSnap.exists || !roundSnap.exists) {
      throw new HttpsError("not-found", "Duel or round not found.");
    }
    const duel = duelSnap.data() as DuelDoc;
    const round = roundSnap.data() as RoundDoc;

    if (round.status !== "active" || duel.currentRound !== roundNumber) {
      throw new HttpsError("failed-precondition", "This round is no longer accepting answers.");
    }
    if (uid !== duel.player1Id && uid !== duel.player2Id) {
      throw new HttpsError("permission-denied", "You are not a player in this duel.");
    }
    if (answersSnap.docs.some((d) => d.id === uid)) {
      throw new HttpsError("already-exists", "You already answered this round.");
    }

    tx.set(answersRef.doc(uid), { selectedIndex, answeredAt });

    const allAnswers: AnswerInput[] = [
      ...answersSnap.docs.map((d) => ({
        uid: d.id,
        ...(d.data() as { selectedIndex: number; answeredAt: FirebaseFirestore.Timestamp }),
      })),
      { uid, selectedIndex, answeredAt },
    ];

    const bothPlayersHaveAnswered =
      allAnswers.some((a) => a.uid === duel.player1Id) && allAnswers.some((a) => a.uid === duel.player2Id);

    return { duel, round, allAnswers, bothPlayersHaveAnswered };
  });

  // Step 2: if that was the second answer, resolve the round in a separate
  // transaction (needs its own fresh reads — the next question, both
  // players' current ELO — that can't happen inside the transaction above
  // once it had already performed a write).
  if (result.bothPlayersHaveAnswered) {
    await resolveRoundNow(duelId, roundNumber, result.duel, result.round, result.allAnswers);
  }
}

/** Used by the scheduled cleanup (`expireStaleRounds.ts`) to force-resolve a
 * round where one or both players never answered in time. */
export async function forceResolveStaleRound(duelId: string): Promise<void> {
  const duelRef = db.collection("duels").doc(duelId);
  const duelSnap = await duelRef.get();
  if (!duelSnap.exists) return;
  const duel = duelSnap.data() as DuelDoc;

  const roundRef = duelRef.collection("rounds").doc(String(duel.currentRound));
  const roundSnap = await roundRef.get();
  if (!roundSnap.exists) return;
  const round = roundSnap.data() as RoundDoc;
  if (round.status !== "active") return;

  const answersSnap = await roundRef.collection("answers").get();
  const answeredUids = new Set(answersSnap.docs.map((d) => d.id));
  const now = Timestamp.now();

  const answers: AnswerInput[] = [duel.player1Id, duel.player2Id].map((uid) => {
    const existing = answersSnap.docs.find((d) => d.id === uid);
    if (existing) {
      const data = existing.data() as { selectedIndex: number; answeredAt: FirebaseFirestore.Timestamp };
      return { uid, selectedIndex: data.selectedIndex, answeredAt: data.answeredAt };
    }
    return { uid, selectedIndex: -1, answeredAt: now };
  });

  if (answeredUids.size === 2) return; // both already in — a normal resolution is already handling this

  await resolveRoundNow(duelId, duel.currentRound, duel, round, answers);
}

async function resolveRoundNow(
  duelId: string,
  roundNumber: number,
  duel: DuelDoc,
  round: RoundDoc,
  answers: AnswerInput[],
): Promise<void> {
  const duelRef = db.collection("duels").doc(duelId);
  const roundRef = duelRef.collection("rounds").doc(String(roundNumber));

  const isFinalRound = roundNumber >= duel.totalRounds;
  // Excludes every question used so far THIS duel, not just the round that
  // just finished — otherwise a short category (or an unlucky random pick)
  // can repeat a question from an earlier round.
  const nextQuestion = isFinalRound
    ? null
    : await pickNextQuestion(duel.categoryId, duel.language, duel.usedQuestionIds ?? [round.questionId]);
  // Fetched before the transaction starts (a question's correct answer
  // never changes after creation, so this doesn't need transactional
  // consistency, and every read inside a Firestore transaction must go
  // through `tx.get()` — this one legitimately doesn't need to).
  const correctAnswerIndex = await getCorrectAnswerIndex(round.questionId);

  await db.runTransaction(async (tx) => {
    // --- re-read inside the transaction so we never award points twice if
    // two triggers race (e.g. a client's timeout submission arrives at the
    // same moment the scheduled cleanup fires), and so score updates are
    // based on the freshest duel state ---
    const [duelSnap, roundSnap, player1Snap, player2Snap] = await Promise.all([
      tx.get(duelRef),
      tx.get(roundRef),
      tx.get(db.collection("users").doc(duel.player1Id)),
      tx.get(db.collection("users").doc(duel.player2Id)),
    ]);
    const freshDuel = duelSnap.data() as DuelDoc;
    const freshRound = roundSnap.data() as RoundDoc;
    if (freshRound.status === "resolved") return; // already handled, nothing to do

    const timeLimitMs = ROUND_TIME_LIMIT_SECONDS * 1000;

    const pointsAwarded: Record<string, number> = {};
    const playerAnswers: Record<string, number> = {};

    for (const answer of answers) {
      playerAnswers[answer.uid] = answer.selectedIndex;
      const isCorrect = answer.selectedIndex === correctAnswerIndex;
      let points = 0;
      if (isCorrect) {
        // `round.startedAt` is read back from an existing document here, so
        // it's always a resolved Timestamp in practice — the FieldValue
        // half of its type only applies when *writing* a new round doc.
        const startedAt = round.startedAt as FirebaseFirestore.Timestamp;
        const latencyMs = Math.max(0, answer.answeredAt.toMillis() - startedAt.toMillis());
        const speedFraction = Math.max(0, 1 - latencyMs / timeLimitMs);
        points = BASE_POINTS_CORRECT + Math.round(MAX_SPEED_BONUS * speedFraction);
      }
      if (duel.isHomeTurfDuel && answer.uid === duel.homeTurfOwnerId) {
        points = Math.round(points * HOME_TURF_MULTIPLIER);
      }
      pointsAwarded[answer.uid] = points;
    }

    tx.update(roundRef, {
      status: "resolved",
      correctAnswerIndex,
      playerAnswers,
      pointsAwarded,
    });

    const newPlayer1Score = freshDuel.player1Score + (pointsAwarded[duel.player1Id] ?? 0);
    const newPlayer2Score = freshDuel.player2Score + (pointsAwarded[duel.player2Id] ?? 0);

    if (!isFinalRound && nextQuestion) {
      const nextRoundNumber = roundNumber + 1;
      tx.update(duelRef, {
        player1Score: newPlayer1Score,
        player2Score: newPlayer2Score,
        currentRound: nextRoundNumber,
        usedQuestionIds: FieldValue.arrayUnion(nextQuestion.id),
      });
      tx.set(duelRef.collection("rounds").doc(String(nextRoundNumber)), {
        roundNumber: nextRoundNumber,
        questionId: nextQuestion.id,
        questionText: nextQuestion.data.questionText,
        options: nextQuestion.data.options,
        difficulty: nextQuestion.data.difficulty,
        status: "active",
        correctAnswerIndex: null,
        playerAnswers: {},
        pointsAwarded: {},
        startedAt: FieldValue.serverTimestamp(),
      } satisfies Partial<RoundDoc>);
      return;
    }

    // --- Final round: finalize the whole duel (win/loss/draw + ELO) ---
    const player1 = player1Snap.data()!;
    const player2 = player2Snap.data()!;

    let winnerId: string | null;
    let actualScorePlayer1: number;
    if (newPlayer1Score > newPlayer2Score) {
      winnerId = duel.player1Id;
      actualScorePlayer1 = 1;
    } else if (newPlayer2Score > newPlayer1Score) {
      winnerId = duel.player2Id;
      actualScorePlayer1 = 0;
    } else {
      winnerId = ""; // draw — empty string, not null, distinguishes "finished as a draw" from "not finished"
      actualScorePlayer1 = 0.5;
    }

    const delta1 = eloDelta(player1.elo, player2.elo, actualScorePlayer1);
    const delta2 = eloDelta(player2.elo, player1.elo, 1 - actualScorePlayer1);

    tx.update(duelRef, {
      player1Score: newPlayer1Score,
      player2Score: newPlayer2Score,
      status: "completed",
      winnerId,
      eloChange: { [duel.player1Id]: delta1, [duel.player2Id]: delta2 },
      completedAt: FieldValue.serverTimestamp(),
    });

    updatePlayerAfterDuel(tx, duel.player1Id, player1, delta1, winnerId === duel.player1Id, winnerId === "");
    updatePlayerAfterDuel(tx, duel.player2Id, player2, delta2, winnerId === duel.player2Id, winnerId === "");

    const [playerAId, playerBId] = [duel.player1Id, duel.player2Id].sort();
    const pairingRef = db.collection("leaderboardPairings").doc(`${playerAId}_${playerBId}`);
    const winnerIsPlayerA = winnerId === playerAId;
    tx.set(
      pairingRef,
      {
        playerAId,
        playerBId,
        playerAWins: FieldValue.increment(winnerId !== "" && winnerIsPlayerA ? 1 : 0),
        playerBWins: FieldValue.increment(winnerId !== "" && !winnerIsPlayerA ? 1 : 0),
        lastDuelAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

export function updatePlayerAfterDuel(
  tx: FirebaseFirestore.Transaction,
  uid: string,
  current: FirebaseFirestore.DocumentData,
  eloChangeAmount: number,
  won: boolean,
  isDraw: boolean,
): void {
  const newStreak = isDraw ? 0 : won ? (current.currentStreak ?? 0) + 1 : 0;
  tx.update(db.collection("users").doc(uid), {
    elo: (current.elo ?? 1200) + eloChangeAmount,
    wins: FieldValue.increment(!isDraw && won ? 1 : 0),
    losses: FieldValue.increment(!isDraw && !won ? 1 : 0),
    currentStreak: newStreak,
    bestStreak: Math.max(current.bestStreak ?? 0, newStreak),
  });
}

async function getCorrectAnswerIndex(questionId: string): Promise<number> {
  const snap = await db.collection("questions").doc(questionId).get();
  const data = snap.data() as QuestionDoc | undefined;
  return data?.correctAnswerIndex ?? 0;
}

/** Picks a random question for `categoryId` in `language`, avoiding
 * `excludeIds` when possible (falls back to allowing a repeat if the
 * category is too small — expected for a brand-new home-turf category).
 *
 * Falls back to ignoring the language filter entirely if the category has
 * no questions in that language yet (e.g. an Arabic-only home-turf category
 * being played by an English-preferring guest, or vice versa) — a duel with
 * mixed-language rounds is a smaller problem than a duel that can't start
 * or can't find a second question at all. */
export async function pickNextQuestion(
  categoryId: string,
  language: string,
  excludeIds: string[],
): Promise<{ id: string; data: QuestionDoc } | null> {
  const byLanguageSnap = await db
    .collection("questions")
    .where("categoryId", "==", categoryId)
    .where("language", "==", language)
    .limit(50)
    .get();

  const snap = byLanguageSnap.empty
    ? await db.collection("questions").where("categoryId", "==", categoryId).limit(50).get()
    : byLanguageSnap;
  if (snap.empty) return null;

  const fresh = snap.docs.filter((d) => !excludeIds.includes(d.id));
  const pool = fresh.length > 0 ? fresh : snap.docs;
  const chosen = pool[Math.floor(Math.random() * pool.length)];
  return { id: chosen.id, data: chosen.data() as QuestionDoc };
}
