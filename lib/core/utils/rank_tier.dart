import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// The named rank a player's ELO puts them in.
///
/// ELO on its own is a number that means nothing to a new player — "2,480"
/// answers no question they were asking. The tier is what the rating is
/// *for*: something to be, and something visibly next. Purely presentational,
/// derived from the same `elo` field the server already maintains, so there
/// is nothing extra to store or keep in sync.
///
/// Distinct from `LevelCalculator`'s [LevelTier], which grades the
/// never-decreasing XP milestone track. This one grades the rating, and it
/// can go down.
enum RankTier {
  noviceClay(floor: 0, ceiling: 500),
  bronzeSpartan(floor: 501, ceiling: 1200),
  silverGladiator(floor: 1201, ceiling: 2000),
  goldTitan(floor: 2001, ceiling: 3000),
  colossusMythic(floor: 3001, ceiling: null);

  const RankTier({required this.floor, required this.ceiling});

  /// Lowest ELO in this tier.
  final int floor;

  /// Highest ELO in this tier; null for the open-ended top tier.
  final int? ceiling;

  static RankTier forElo(int elo) {
    for (final tier in values) {
      if (tier.ceiling == null || elo <= tier.ceiling!) return tier;
    }
    return colossusMythic;
  }

  bool get isMax => ceiling == null;

  /// ELO still needed to reach the next tier; 0 once at the top.
  int eloToNext(int elo) => isMax ? 0 : (ceiling! + 1 - elo).clamp(0, ceiling! + 1);

  /// 0.0–1.0 progress through this tier, for a progress bar.
  double progress(int elo) {
    if (isMax) return 1;
    final span = ceiling! - floor;
    if (span <= 0) return 1;
    return ((elo - floor) / span).clamp(0.0, 1.0);
  }

  Color get color => switch (this) {
    RankTier.noviceClay => AppColors.textDisabled,
    RankTier.bronzeSpartan => AppColors.playerOne,
    RankTier.silverGladiator => AppColors.gold,
    RankTier.goldTitan => AppColors.playerTwo,
    RankTier.colossusMythic => AppColors.primary,
  };

  /// Readable against [color] when it's used as a filled badge background.
  Color get onColor => switch (this) {
    RankTier.silverGladiator => AppColors.onBrand,
    RankTier.colossusMythic => AppColors.gold,
    _ => AppColors.onArena,
  };
}
