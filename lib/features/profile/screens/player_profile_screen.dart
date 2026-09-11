import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/rank_tier.dart';
import '../../../core/widgets/branded_loading_indicator.dart';
import '../../../core/widgets/rank_badge.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../duel/widgets/challenge_category_sheet.dart';
import '../../friends/friends_controller.dart';
import '../../friends/widgets/friend_request_card.dart';
import '../../leaderboard/leaderboard_controller.dart';
import '../widgets/stat_tile.dart';

/// A read-only view of another player's profile — reached from a past duel
/// (`RecentDuelTile`, `DuelResultScreen`), a friends-list row, or a search
/// result — rather than from the bottom nav, so unlike `ProfileScreen`
/// there's no edit name, sign out, or language toggle here. What it adds
/// instead: the head-to-head record against whoever's viewing it, and
/// (unless it's your own profile) a friend-request/Challenge action that
/// reflects however the two of you currently relate.
class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final userAsync = ref.watch(userByIdProvider(uid));
    final myUid = ref.watch(currentUserIdProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(userAsync.value?.displayName ?? '')),
      body: userAsync.when(
        loading: () => const Center(child: BrandedLoadingIndicator()),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (user) {
          if (user == null) return Center(child: Text(l10n.commonError));

          final tier = RankTier.forElo(user.elo);
          final name = user.displayName.trim();

          return ResponsiveCenter(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tier.color.withValues(alpha: 0.16),
                      border: Border.all(color: tier.color, width: 2.5),
                      image: user.photoUrl != null
                          ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: user.photoUrl != null
                        ? null
                        : Text(
                            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                            style: theme.textTheme.displaySmall?.copyWith(color: tier.color),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(child: Text(name, style: theme.textTheme.displaySmall)),
                const SizedBox(height: AppSpacing.xs),
                Center(child: RankBadge(tier: tier)),

                const SizedBox(height: AppSpacing.lg),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: StatTile(
                          label: l10n.profileWins,
                          value: '${user.wins}',
                          accentColor: AppColors.success,
                          emphasis: StatEmphasis.hero,
                          icon: Icons.military_tech_rounded,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatTile(
                          label: l10n.profileLosses,
                          value: '${user.losses}',
                          accentColor: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatTile(
                          label: l10n.profileEloRating,
                          value: Formatters.elo(user.elo, locale: locale),
                          accentColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                if (myUid != null && myUid != uid) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _FriendAction(myUid: myUid, otherUid: uid, otherDisplayName: user.displayName),
                  const SizedBox(height: AppSpacing.lg),
                  _HeadToHeadCard(myUid: myUid, opponentUid: uid, l10n: l10n),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// However [myUid] and [otherUid] currently relate — no request yet, one
/// pending either direction, or already friends — decides which single
/// action makes sense here: send a request, show it's already sent, let the
/// viewer accept/decline one they received, or jump straight to a
/// Challenge once you're friends.
class _FriendAction extends ConsumerWidget {
  const _FriendAction({required this.myUid, required this.otherUid, required this.otherDisplayName});

  final String myUid;
  final String otherUid;
  final String otherDisplayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myFriendships = ref.watch(myFriendshipsProvider).value ?? const [];
    final relation = friendRelationWith(myFriendships, myUid, otherUid);

    return switch (relation) {
      FriendRelation.none => SlabButton(
        label: l10n.friendsSendRequest,
        icon: Icons.person_add_alt_1_rounded,
        onPressed: () => ref.read(friendsControllerProvider.notifier).sendRequest(otherUid),
      ),
      FriendRelation.requestSent => SlabButton(
        label: l10n.friendsRequestSent,
        background: AppColors.surfaceRaised,
        foreground: AppColors.textSecondary,
        depthColor: AppColors.surfaceBorder,
        onPressed: null,
      ),
      FriendRelation.requestReceived => FriendRequestCard(
        fromDisplayName: otherDisplayName,
        onAccept: () => ref
            .read(friendsControllerProvider.notifier)
            .respondToRequest(otherUserId: otherUid, accept: true),
        onDecline: () => ref
            .read(friendsControllerProvider.notifier)
            .respondToRequest(otherUserId: otherUid, accept: false),
      ),
      FriendRelation.friends => SlabButton(
        label: l10n.friendsChallenge,
        icon: Icons.bolt_rounded,
        onPressed: () => showChallengeCategorySheet(context, toUserId: otherUid),
      ),
    };
  }
}

/// "You beat them 3-2" without digging through past duels by hand.
class _HeadToHeadCard extends ConsumerWidget {
  const _HeadToHeadCard({required this.myUid, required this.opponentUid, required this.l10n});

  final String myUid;
  final String opponentUid;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordAsync = ref.watch(headToHeadProvider((uidA: myUid, uidB: opponentUid)));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: recordAsync.when(
        loading: () => const Center(child: BrandedLoadingIndicator()),
        error: (_, _) => Text(l10n.commonError, textAlign: TextAlign.center),
        data: (HeadToHeadRecordModel? record) {
          final wins = record?.winsFor(myUid) ?? 0;
          final losses = record?.lossesFor(myUid) ?? 0;

          return Column(
            children: [
              Text(
                l10n.playerProfileHeadToHeadTitle.toUpperCase(),
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (record == null)
                Text(
                  l10n.playerProfileNeverPlayed,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.ltr,
                  children: [
                    Text(
                      '$wins',
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.displayMedium?.copyWith(color: AppColors.playerOne),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('—', style: theme.textTheme.headlineMedium),
                    ),
                    Text(
                      '$losses',
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.displayMedium?.copyWith(color: AppColors.playerTwo),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
