import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/rank_tier.dart';
import '../../../core/widgets/arena_panel.dart';
import '../../../core/widgets/rank_badge.dart';
import '../../../l10n/app_localizations.dart';

/// The home screen's hero: a full-bleed arena field with the player's rating
/// set enormous in the display face.
///
/// This replaced a gold gradient stat *card*. The difference is the point of
/// the redesign — a card announces "here is a number in a box"; a field the
/// rating is printed directly onto announces the rating itself. Nothing here
/// is inset from the screen edge except the text.
class ArenaRatingHeader extends StatelessWidget {
  const ArenaRatingHeader({
    super.key,
    required this.displayName,
    required this.elo,
    required this.wins,
    required this.losses,
  });

  final String displayName;
  final int elo;
  final int wins;
  final int losses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final tier = RankTier.forElo(elo);
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().characters.first.toUpperCase();

    return ArenaPanel(
      gradient: AppColors.arenaGradient,
      slantHeight: 30,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                ),
                child: Text(
                  initial,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    RankBadge(tier: tier, compact: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.homeEloLabel.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.elo(elo, locale: locale),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 52, color: AppColors.gold),
              ),
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  // Pinned LTR — "12-5" reorders under RTL bidi rules.
                  Formatters.record(wins, losses),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onArenaMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          RankProgressBar(tier: tier, elo: elo),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tier.isMax
                ? l10n.homeTierMaxed.toUpperCase()
                : l10n
                      .homeTierProgress(
                        tier.eloToNext(elo),
                        RankTier.values[tier.index + 1].label(l10n),
                      )
                      .toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
