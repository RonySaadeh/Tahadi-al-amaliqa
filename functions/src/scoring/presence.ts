import { HttpsError, onCall } from "firebase-functions/v2/https";
import { db, FieldValue, Timestamp } from "../lib/admin";
import { DUEL_RECONNECT_GRACE_SECONDS } from "../lib/constants";
import { DuelDoc } from "../lib/types";
import { eloDelta } from "./eloCalculator";
import { updatePlayerAfterDuel } from "./resolveDuel";

/**
 * Connection-loss handling for an active duel. Two callables:
 *
 * - `heartbeat`: a player's client pings this every
 *   `DUEL_HEARTBEAT_INTERVAL_SECONDS` while `LiveDuelScreen` is on screen and
 *   the duel is active, stamping their `player{1,2}LastSeenAt` field with
 *   the *server's* clock (never the client's — same reasoning as
 *   `submitAnswer.ts`).
 * - `forfeitDuel`: called by the still-connected player once their
 *   opponent's last heartbeat is older than `DUEL_RECONNECT_GRACE_SECONDS`
 *   — the "35 second reconnecting phase" the client shows the disconnected
 *   player. Re-validates staleness against the stored server timestamps
 *   before awarding the win, so a client can't fabricate a forfeit against
 *   an opponent who is actually still connected.
 */

export const heartbeat = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const { duelId } = request.data as { duelId?: unknown };
  if (typeof duelId !== "string" || duelId.length === 0) {
    throw new HttpsError("invalid-argument", "duelId is required.");
  }

  const duelRef = db.collection("duels").doc(duelId);
  const duelSnap = await duelRef.get();
  if (!duelSnap.exists) {
    throw new HttpsError("not-found", "Duel not found.");
  }
  const duel = duelSnap.data() as DuelDoc;

  if (uid !== duel.player1Id && uid !== duel.player2Id) {
    throw new HttpsError("permission-denied", "You are not a player in this duel.");
  }

  // A finished duel doesn't need presence tracking any more — a no-op keeps
  // a client that hasn't noticed the duel ended yet from erroring.
  if (duel.status !== "active") {
    return { success: true };
  }

  const field = uid === duel.player1Id ? "player1LastSeenAt" : "player2LastSeenAt";
  await duelRef.update({ [field]: FieldValue.serverTimestamp() });
  return { success: true };
});

export const forfeitDuel = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const { duelId } = request.data as { duelId?: unknown };
  if (typeof duelId !== "string" || duelId.length === 0) {
    throw new HttpsError("invalid-argument", "duelId is required.");
  }

  await resolveForfeit(duelId, uid);
  return { success: true };
});

async function resolveForfeit(duelId: string, callerUid: string): Promise<void> {
  const duelRef = db.collection("duels").doc(duelId);

  await db.runTransaction(async (tx) => {
    const duelSnap = await tx.get(duelRef);
    if (!duelSnap.exists) {
      throw new HttpsError("not-found", "Duel not found.");
    }
    const duel = duelSnap.data() as DuelDoc;

    // Already finished (a normal round resolution, or the other player beat
    // us to claiming this same forfeit) — nothing to do, not an error.
    if (duel.status !== "active") return;

    if (callerUid !== duel.player1Id && callerUid !== duel.player2Id) {
      throw new HttpsError("permission-denied", "You are not a player in this duel.");
    }

    const opponentId = callerUid === duel.player1Id ? duel.player2Id : duel.player1Id;
    const callerLastSeenAt = callerUid === duel.player1Id ? duel.player1LastSeenAt : duel.player2LastSeenAt;
    const opponentLastSeenAt = callerUid === duel.player1Id ? duel.player2LastSeenAt : duel.player1LastSeenAt;

    const now = Timestamp.now();
    const graceMs = DUEL_RECONNECT_GRACE_SECONDS * 1000;

    // The caller must themselves have a recent heartbeat — otherwise a
    // client that's been backgrounded for a long time could wake up and
    // immediately claim a stale forfeit against an opponent who reconnected
    // ages ago.
    const callerRecent =
      callerLastSeenAt != null &&
      now.toMillis() - (callerLastSeenAt as FirebaseFirestore.Timestamp).toMillis() <= graceMs;
    if (!callerRecent) {
      throw new HttpsError("failed-precondition", "You must be actively connected to claim a forfeit.");
    }

    const referenceTimestamp =
      opponentLastSeenAt ?? (duel.startedAt as FirebaseFirestore.Timestamp | null) ?? duel.createdAt;
    const opponentStaleMs = now.toMillis() - (referenceTimestamp as FirebaseFirestore.Timestamp).toMillis();
    if (opponentStaleMs < graceMs) {
      throw new HttpsError("failed-precondition", "Your opponent is still connected.");
    }

    const [callerSnap, opponentSnap] = await Promise.all([
      tx.get(db.collection("users").doc(callerUid)),
      tx.get(db.collection("users").doc(opponentId)),
    ]);
    const callerUser = callerSnap.data()!;
    const opponentUser = opponentSnap.data()!;

    const callerDelta = eloDelta(callerUser.elo, opponentUser.elo, 1);
    const opponentDelta = eloDelta(opponentUser.elo, callerUser.elo, 0);

    tx.update(duelRef, {
      status: "completed",
      winnerId: callerUid,
      eloChange: { [callerUid]: callerDelta, [opponentId]: opponentDelta },
      completedAt: FieldValue.serverTimestamp(),
    });

    updatePlayerAfterDuel(tx, callerUid, callerUser, callerDelta, true, false);
    updatePlayerAfterDuel(tx, opponentId, opponentUser, opponentDelta, false, false);
  });
}
