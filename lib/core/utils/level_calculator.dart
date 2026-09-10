import 'dart:math' as math;

/// Visual tier a level belongs to — purely cosmetic grouping for the badge
/// color, no gameplay effect.
enum LevelTier { bronze, silver, gold, diamond }

/// A player's computed level, XP, and progress toward the next one.
class PlayerLevel {
  const PlayerLevel({
    required this.level,
    required this.tier,
    required this.xp,
    required this.xpIntoLevel,
    required this.xpSpanForLevel,
  });

  final int level;
  final LevelTier tier;
  final int xp;

  /// XP earned since hitting [level] (0 at the start of the level).
  final int xpIntoLevel;

  /// Total XP needed to go from [level] to the next one.
  final int xpSpanForLevel;

  /// 0.0-1.0 progress through the current level, for a progress bar.
  double get progress => xpSpanForLevel == 0 ? 1.0 : xpIntoLevel / xpSpanForLevel;
}

/// Turns a player's wins/losses into a level — entirely derived client-side
/// from stats the app already tracks, so there's no new Firestore field or
/// Cloud Function to keep in sync. This is a separate progression track
/// from ELO on purpose: ELO can go down (it's a *rating*, relative to who
/// you played), but a level never should (it's a *milestone*, purely
/// additive) — someone on a losing streak still keeps leveling up, just
/// more slowly than if they'd won.
///
/// XP: +30 per win, +10 per loss (showing up and playing still counts for
/// something, just less than winning). Levels grow quadratically
/// (`xpToReach(level) = 100 * (level - 1)²`), the classic "each level takes
/// longer than the last" RPG curve — level 2 needs 100 XP (~3-4 wins),
/// level 5 needs 1,600 XP, level 10 needs 8,100 XP.
class LevelCalculator {
  const LevelCalculator._();

  static const int xpPerWin = 30;
  static const int xpPerLoss = 10;
  static const int _xpUnit = 100;

  static int xpFor({required int wins, required int losses}) => wins * xpPerWin + losses * xpPerLoss;

  static int _xpToReach(int level) {
    final n = level - 1;
    return _xpUnit * n * n;
  }

  static PlayerLevel calculate({required int wins, required int losses}) {
    final xp = xpFor(wins: wins, losses: losses);
    final level = 1 + math.sqrt(xp / _xpUnit).floor();
    final currentThreshold = _xpToReach(level);
    final nextThreshold = _xpToReach(level + 1);
    return PlayerLevel(
      level: level,
      tier: _tierFor(level),
      xp: xp,
      xpIntoLevel: xp - currentThreshold,
      xpSpanForLevel: nextThreshold - currentThreshold,
    );
  }

  static LevelTier _tierFor(int level) {
    if (level >= 20) return LevelTier.diamond;
    if (level >= 10) return LevelTier.gold;
    if (level >= 5) return LevelTier.silver;
    return LevelTier.bronze;
  }
}
