import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/rank_tier.dart';

/// Localized display name for a rank. Kept as an extension rather than a
/// field on [RankTier] so the enum stays free of any Flutter/l10n import and
/// can be unit-tested on its own.
extension RankTierLabel on RankTier {
  String label(AppLocalizations l10n) => switch (this) {
    RankTier.noviceClay => l10n.rankNoviceClay,
    RankTier.bronzeSpartan => l10n.rankBronzeSpartan,
    RankTier.silverGladiator => l10n.rankSilverGladiator,
    RankTier.goldTitan => l10n.rankGoldTitan,
    RankTier.colossusMythic => l10n.rankColossusMythic,
  };
}

/// The small filled chip naming a player's rank — "GOLD TITAN". Sits next to
/// a rating number so the number has something to mean.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.tier, this.compact = false});

  final RankTier tier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: tier.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        tier.label(l10n).toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tier.onColor,
          fontSize: compact ? 9 : 10,
        ),
      ),
    );
  }
}

/// A thin progress rail showing how far into the current rank a player is.
/// Reads as a stripe of the tier's own color rather than a Material
/// `LinearProgressIndicator`, so it belongs to the badge beside it.
class RankProgressBar extends StatelessWidget {
  const RankProgressBar({super.key, required this.tier, required this.elo, this.onDark = true});

  final RankTier tier;
  final int elo;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: onDark ? AppColors.arenaRaised : AppColors.surfaceRaised,
              ),
            ),
            FractionallySizedBox(
              widthFactor: tier.progress(elo).clamp(0.02, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tier.color.withValues(alpha: 0.65), tier.color],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
