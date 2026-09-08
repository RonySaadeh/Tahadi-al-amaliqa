import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../l10n/app_localizations.dart';

class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({super.key, required this.rank, required this.entry, required this.onTap, this.isMe = false});

  final int rank;
  final LeaderboardEntryModel entry;
  final VoidCallback onTap;
  final bool isMe;

  Color get _rankColor => switch (rank) {
    1 => AppColors.gold,
    2 => const Color(0xFFC0C0C0),
    3 => const Color(0xFFCD7F32),
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: isMe ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  l10n.leaderboardRank(rank),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _rankColor, fontWeight: FontWeight.w800),
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceRaised,
                backgroundImage: entry.photoUrl != null ? NetworkImage(entry.photoUrl!) : null,
                child: entry.photoUrl == null
                    ? Text(entry.displayName.isNotEmpty ? entry.displayName[0] : '?')
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.displayName, style: Theme.of(context).textTheme.titleMedium),
                    Text(Formatters.record(entry.wins, entry.losses), style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Text(
                Formatters.elo(entry.elo),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
