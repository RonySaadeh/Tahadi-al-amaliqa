import { onSchedule } from "firebase-functions/v2/scheduler";
import { db, Timestamp } from "../lib/admin";
import { ROUND_TIME_LIMIT_SECONDS, STALE_ROUND_GRACE_SECONDS } from "../lib/constants";
import { DuelDoc } from "../lib/types";
import { forceResolveStaleRound } from "./resolveDuel";

/**
 * Safety net for abandoned rounds: normally a round resolves the instant
 * both players answer (or a client self-reports a timeout — see
 * `submitAnswer.ts`), but if someone closes the app mid-round, nothing
 * client-side will ever submit their answer. This runs every 30 seconds,
 * finds any duel whose current round has been open well past its time
 * limit, and force-resolves it (missing players score 0 for that round)
 * so the other player's game isn't stuck waiting forever.
 */
export const expireStaleRounds = onSchedule("every 30 seconds", async () => {
  const cutoff = Timestamp.fromMillis(
    Date.now() - (ROUND_TIME_LIMIT_SECONDS + STALE_ROUND_GRACE_SECONDS) * 1000,
  );

  const activeDuelsSnap = await db.collection("duels").where("status", "==", "active").get();

  await Promise.all(
    activeDuelsSnap.docs.map(async (duelDoc) => {
      const duel = duelDoc.data() as DuelDoc;
      const roundRef = duelDoc.ref.collection("rounds").doc(String(duel.currentRound));
      const roundSnap = await roundRef.get();
      if (!roundSnap.exists) return;

      const round = roundSnap.data()!;
      if (round.status !== "active") return;
      if ((round.startedAt as FirebaseFirestore.Timestamp).toMillis() > cutoff.toMillis()) return;

      await forceResolveStaleRound(duelDoc.id);
    }),
  );
});
