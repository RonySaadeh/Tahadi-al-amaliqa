import { ELO_K_FACTOR } from "../lib/constants";

/**
 * Pure ELO math — no Firestore, no side effects, fully unit-testable on its
 * own. `resolveDuel.ts` is the only caller; kept separate so the formula
 * itself is easy to find and reason about without wading through
 * transaction/Firestore plumbing.
 */

/** Standard ELO expected-score formula: the probability [0, 1] that A beats B. */
export function expectedScore(ratingA: number, ratingB: number): number {
  return 1 / (1 + Math.pow(10, (ratingB - ratingA) / 400));
}

/**
 * `actualScoreA` is 1 for a win, 0 for a loss, 0.5 for a draw.
 * Returns the signed rating change for player A (player B's is the mirror
 * call with the arguments swapped).
 */
export function eloDelta(
  ratingA: number,
  ratingB: number,
  actualScoreA: number,
  kFactor: number = ELO_K_FACTOR,
): number {
  const expected = expectedScore(ratingA, ratingB);
  return Math.round(kFactor * (actualScoreA - expected));
}
