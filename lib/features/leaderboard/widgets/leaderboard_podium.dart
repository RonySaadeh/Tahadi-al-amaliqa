import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/leaderboard_entry_model.dart';

/// The top three, built as an actual podium rather than the first three rows
/// of a list.
///
/// A ranking where rank 1 and rank 20 are the same rectangle communicates
/// nothing about the distance between them. Here first place is physically
/// taller, wider, gold, and centered — the standing order is readable before
/// a single name is.
///
/// Renders whatever it's given: with one or two entries the missing plinths
/// simply don't appear, so a young leaderboard degrades cleanly.
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({super.key, required this.entries, required this.myUid, required this.onTap});

  /// Ranked best-first. Only the first three are used.
  final List<LeaderboardEntryModel> entries;
  final String? myUid;
  final void Function(LeaderboardEntryModel entry) onTap;

  static const Color _silver = Color(0xFFC0C0C0);
  static const Color _bronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    final top = entries.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    // Visual order puts the winner in the middle, not first.
    final second = top.length > 1 ? top[1] : null;
    final first = top[0];
    final third = top.length > 2 ? top[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second == null
              ? const SizedBox.shrink()
              : _Plinth(
                  entry: second,
                  rank: 2,
                  color: _silver,
                  height: 66,
                  isMe: second.uid == myUid,
                  onTap: () => onTap(second),
                ),
        ),
        Expanded(
          child: _Plinth(
            entry: first,
            rank: 1,
            color: AppColors.gold,
            height: 96,
            isMe: first.uid == myUid,
            onTap: () => onTap(first),
          ),
        ),
        Expanded(
          child: third == null
              ? const SizedBox.shrink()
              : _Plinth(
                  entry: third,
                  rank: 3,
                  color: _bronze,
                  height: 50,
                  isMe: third.uid == myUid,
                  onTap: () => onTap(third),
                ),
        ),
      ],
    );
  }
}

class _Plinth extends StatelessWidget {
  const _Plinth({
    required this.entry,
    required this.rank,
    required this.color,
    required this.height,
    required this.isMe,
    required this.onTap,
  });

  final LeaderboardEntryModel entry;
  final int rank;
  final Color color;
  final double height;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChampion = rank == 1;
    final avatarSize = isChampion ? 56.0 : 42.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isChampion) ...[
            Icon(Icons.workspace_premium_rounded, color: color, size: 22),
            const SizedBox(height: 2),
          ],
          Container(
            width: avatarSize,
            height: avatarSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color, width: isChampion ? 3 : 2),
              boxShadow: isChampion
                  ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 24)]
                  : null,
            ),
            child: entry.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      entry.photoUrl!,
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _Initial(entry: entry, color: color),
                    ),
                  )
                : _Initial(entry: entry, color: color),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isMe ? color : Colors.white,
                fontSize: isChampion ? 13 : 11,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: isChampion
                  ? AppColors.goldGradient
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.arenaRaised, AppColors.arenaDeep],
                    ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSm)),
            ),
            child: Column(
              children: [
                Text(
                  '$rank',
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: isChampion ? 22 : 16,
                    color: isChampion ? AppColors.onBrand : color,
                  ),
                ),
                Text(
                  Formatters.elo(entry.elo),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: isChampion
                        ? AppColors.onBrand.withValues(alpha: 0.75)
                        : AppColors.onArenaMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.entry, required this.color});

  final LeaderboardEntryModel entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final name = entry.displayName.trim();
    return Center(
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
