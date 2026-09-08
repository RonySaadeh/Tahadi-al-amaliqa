import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';

/// The hero "your rating" card at the top of the home screen — a gold
/// gradient stat tile, the kind of thing a sports app would show for a
/// live ranking rather than a plain label/value row.
class EloStatCard extends StatelessWidget {
  const EloStatCard({super.key, required this.elo, required this.wins, required this.losses});

  final int elo;
  final int wins;
  final int losses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeEloLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onBrand),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(Formatters.elo(elo, locale: locale), style: AppTypography.statNumber.copyWith(color: AppColors.onBrand)),
          const SizedBox(height: AppSpacing.sm),
          // Forced LTR — see the comment on ScorePopup: "12-5" reorders
          // under RTL bidi rules unless pinned.
          Text(
            Formatters.record(wins, losses),
            textDirection: TextDirection.ltr,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onBrand.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
