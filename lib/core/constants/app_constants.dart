/// Gameplay tuning knobs shared by the client (for UI countdowns/estimates)
/// and mirrored in `functions/src/lib/constants.ts` for the server-side
/// scoring math. The Cloud Functions copy is the one that actually decides
/// points — these client-side values are for display only, so keep them in
/// sync manually when you tune the game.
class AppConstants {
  const AppConstants._();

  static const int startingElo = 1200;
  static const int roundsPerDuel = 5;
  static const int roundTimeLimitSeconds = 15;
  static const int maxHomeTurfCategories = 3;

  /// Points for a correct answer, before the speed bonus.
  static const int basePointsCorrect = 100;

  /// Extra points available for answering instantly, decaying linearly to
  /// zero as the player uses up the full time limit.
  static const int maxSpeedBonus = 100;

  /// Multiplier applied to a category owner's points when they duel someone
  /// else on their own home-turf category.
  static const double homeTurfMultiplier = 1.25;

  /// Standard ELO K-factor. Higher = ratings move faster per duel.
  static const int eloKFactor = 32;

  /// Minimum time the splash screen stays up on a cold start, even if auth
  /// and connectivity resolve instantly — long enough to read as a
  /// deliberate branded loading moment, short enough to never feel slow.
  static const int splashMinDurationMs = 900;

  /// How often a client in an active duel pings the `heartbeat` callable —
  /// mirrors `functions/src/lib/constants.ts`.
  static const int duelHeartbeatIntervalSeconds = 8;

  /// How long a player has to reconnect before their opponent can claim an
  /// automatic forfeit win — the "35 second reconnecting phase". Mirrors
  /// `functions/src/lib/constants.ts`; the server re-checks this
  /// independently before honoring a forfeit, so this copy is for the UI
  /// countdown only.
  static const int duelReconnectGraceSeconds = 35;
}
