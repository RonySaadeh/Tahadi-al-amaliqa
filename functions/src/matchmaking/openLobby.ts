import { HttpsError, onCall } from "firebase-functions/v2/https";
import { db, FieldValue } from "../lib/admin";
import { createDuelForPlayers } from "./createDuel";

/**
 * "Quick match": join a queue of players waiting for anyone to duel, rather
 * than challenging one specific friend (see `duelChallenges.ts` for that
 * flow). Backed by the `openLobbies` collection — one document per waiting
 * player.
 */
export const joinOpenLobby = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");

  const { categoryId } = request.data as { categoryId?: unknown };
  const resolvedCategoryId =
    typeof categoryId === "string" && categoryId.length > 0 ? categoryId : await pickRandomCategoryId();

  if (!resolvedCategoryId) {
    throw new HttpsError("failed-precondition", "No categories exist yet to match on.");
  }

  // Look for someone else already waiting on the same category.
  const waitingSnap = await db
    .collection("openLobbies")
    .where("categoryId", "==", resolvedCategoryId)
    .where("status", "==", "open")
    .orderBy("createdAt")
    .limit(5)
    .get();

  const candidate = waitingSnap.docs.find((d) => d.data().hostId !== uid);

  if (candidate) {
    const matched = await db.runTransaction(async (tx) => {
      const freshSnap = await tx.get(candidate.ref);
      if (!freshSnap.exists || freshSnap.data()?.status !== "open") return false;
      tx.update(candidate.ref, { status: "matched" });
      return true;
    });

    if (matched) {
      const hostId = candidate.data().hostId as string;
      const duelId = await createDuelForPlayers(hostId, uid, resolvedCategoryId);
      await candidate.ref.update({ duelId });
      return { duelId, matched: true };
    }
    // Someone else grabbed it between our read and our transaction — fall
    // through and just create our own lobby entry below.
  }

  const lobbyRef = await db.collection("openLobbies").add({
    hostId: uid,
    categoryId: resolvedCategoryId,
    status: "open",
    duelId: null,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { lobbyId: lobbyRef.id, matched: false };
});

export const leaveOpenLobby = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");

  const { lobbyId } = request.data as { lobbyId?: unknown };
  if (typeof lobbyId !== "string" || lobbyId.length === 0) {
    throw new HttpsError("invalid-argument", "lobbyId is required.");
  }

  const lobbyRef = db.collection("openLobbies").doc(lobbyId);
  const lobbySnap = await lobbyRef.get();
  if (!lobbySnap.exists) return { success: true }; // already gone

  if (lobbySnap.data()?.hostId !== uid) {
    throw new HttpsError("permission-denied", "This isn't your lobby entry.");
  }
  await lobbyRef.delete();
  return { success: true };
});

async function pickRandomCategoryId(): Promise<string | null> {
  const snap = await db.collection("categories").limit(50).get();
  if (snap.empty) return null;
  return snap.docs[Math.floor(Math.random() * snap.docs.length)].id;
}
