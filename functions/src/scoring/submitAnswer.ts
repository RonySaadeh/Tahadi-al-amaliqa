import { HttpsError, onCall } from "firebase-functions/v2/https";
import { recordAnswerAndMaybeResolve } from "./resolveDuel";

/**
 * The ONLY way a player's duel answer gets recorded — see the
 * "server-authoritative" note in the Flutter app's
 * `core/services/cloud_functions_service.dart`. The client sends what it
 * picked; this function (running on Google's clock, not the player's
 * phone) timestamps receipt and hands off to `resolveDuel.ts` for the
 * actual scoring.
 *
 * `selectedIndex` of `-1` means "no answer" — the client sends this itself
 * when its local countdown hits zero, so a round usually resolves the
 * instant time is up rather than waiting for `expireStaleRounds` to clean
 * it up.
 */
export const submitAnswer = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const { duelId, roundNumber, selectedIndex } = request.data as {
    duelId?: unknown;
    roundNumber?: unknown;
    selectedIndex?: unknown;
  };

  if (typeof duelId !== "string" || duelId.length === 0) {
    throw new HttpsError("invalid-argument", "duelId is required.");
  }
  if (typeof roundNumber !== "number" || !Number.isInteger(roundNumber) || roundNumber < 1) {
    throw new HttpsError("invalid-argument", "roundNumber must be a positive integer.");
  }
  if (typeof selectedIndex !== "number" || !Number.isInteger(selectedIndex) || selectedIndex < -1 || selectedIndex > 3) {
    throw new HttpsError("invalid-argument", "selectedIndex must be -1 (no answer) or 0-3.");
  }

  await recordAnswerAndMaybeResolve(duelId, roundNumber, uid, selectedIndex);
  return { success: true };
});
