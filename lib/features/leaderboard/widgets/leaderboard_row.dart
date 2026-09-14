import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/avatar_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/rank_tier.dart';
import '../../../core/widgets/modular_avatar.dart';
import '../../../data/models/leaderboard_entry_model.dart';

/// One row of the leaderboard below the podium.
///
/// Deliberately dense and borderless — the podium above already carries all
/// the ceremony, so this half of the screen's job is to be scannable. The
/// local player's row is marked with a violet spine down its leading edge
/// rather than a filled background, so it's findable without becoming
/// another block competing with the podium.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.entry,
    required this.onTap,
    this.isMe = false,
  });

  final int rank;
  final LeaderboardEntryModel entry;
  final VoidCallback onTap;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = RankTier.forElo(entry.elo);
    final name = entry.displayName.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withValues(alpha: 0.07) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: isMe
              ? const Border(left: BorderSide(color: AppColors.primary, width: 3))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 15,
                  color: isMe ? AppColors.primary : AppColors.textDisabled,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            ClipOval(
              child: ModularAvatarWidget(
                archetype: AvatarArchetype.strategist,
                frame: tier.avatarFrame,
                size: 34,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  Text(
                    // Pinned LTR — "12-5" reorders under RTL bidi rules.
                    Formatters.record(entry.wins, entry.losses),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              Formatters.elo(entry.elo),
              textDirection: TextDirection.ltr,
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 17, color: tier.color),
            ),
          ],
        ),
      ),
    );
  }
}
