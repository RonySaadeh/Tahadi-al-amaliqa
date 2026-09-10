/**
 * Gameplay tuning knobs. Mirrors `lib/core/constants/app_constants.dart` on
 * the Flutter side — that copy is display-only, THIS copy is the one that
 * actually decides scoring, so if you want to change how the game plays,
 * change it here (and update the Dart copy so the UI matches).
 */
export const STARTING_ELO = 1200;
export const ROUNDS_PER_DUEL = 5;
export const ROUND_TIME_LIMIT_SECONDS = 15;
export const MAX_HOME_TURF_CATEGORIES = 3;

export const BASE_POINTS_CORRECT = 100;
export const MAX_SPEED_BONUS = 100;
export const HOME_TURF_MULTIPLIER = 1.25;
export const ELO_K_FACTOR = 32;

/** Grace period added on top of the round time limit before the scheduled
 * cleanup (`expireStaleRounds`) force-resolves a round nobody finished
 * answering — gives slow-but-still-connected clients a little slack beyond
 * what their own countdown UI shows. */
export const STALE_ROUND_GRACE_SECONDS = 10;

/** How often a client in an active duel calls the `heartbeat` callable to
 * refresh its `player{1,2}LastSeenAt` field — see `scoring/presence.ts`. */
export const DUEL_HEARTBEAT_INTERVAL_SECONDS = 8;

/** How long a player's last heartbeat may go stale before their opponent is
 * allowed to claim a forfeit win via `forfeitDuel` — this is the "35 second
 * reconnecting phase" shown to the disconnected player on the client. Kept
 * well above `DUEL_HEARTBEAT_INTERVAL_SECONDS` so a couple of missed/delayed
 * heartbeats never falsely cost someone the duel. */
export const DUEL_RECONNECT_GRACE_SECONDS = 35;
