import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/presence.dart';
import '../../../core/utils/rank_tier.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../l10n/app_localizations.dart';

/// One row on the friends list: avatar (with an online dot when
/// applicable), name, last-seen line, and a Challenge button — same
/// avatar/row anatomy as `LeaderboardRow`, so the friends list reads as
/// part of the same app rather than a bolted-on screen.
class FriendRow extends ConsumerWidget {
  const FriendRow({super.key, required this.friendUid, required this.onTap, required this.onChallenge});

  final String friendUid;
  final VoidCallback onTap;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final userAsync = ref.watch(userStreamProvider(friendUid));

    return userAsync.when(
      loading: () => const SkeletonListTile(),
      error: (_, _) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final online = isOnline(user.lastActiveAt);
        final tier = RankTier.forElo(user.elo);
        final name = user.displayName.trim();

        return InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tier.color.withValues(alpha: 0.16),
                        border: Border.all(color: tier.color.withValues(alpha: 0.55), width: 1.5),
                        image: user.photoUrl != null
                            ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: user.photoUrl != null
                          ? null
                          : Text(
                              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: tier.color,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                    if (online)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                            border: Border.all(color: AppColors.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
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
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        lastSeenLabel(user.lastActiveAt, l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: online ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SlabButton(
                  label: l10n.friendsChallenge,
                  expand: false,
                  fontSize: 13,
                  verticalPadding: AppSpacing.sm,
                  background: online ? AppColors.primary : AppColors.surfaceRaised,
                  foreground: online ? Colors.white : AppColors.textSecondary,
                  depthColor: online ? null : AppColors.surfaceBorder,
                  onPressed: onChallenge,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
