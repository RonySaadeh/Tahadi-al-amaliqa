import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/arena_panel.dart';
import '../../../core/widgets/branded_loading_indicator.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../data/models/duel_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../../duel/duel_controller.dart';
import '../../duel/widgets/category_catalog.dart';
import '../../duel/widgets/invite_card.dart';
import '../../notifications/notifications_controller.dart';
import '../home_controller.dart';
import '../widgets/arena_rating_header.dart';
import '../widgets/email_verification_banner.dart';
import '../widgets/recent_duel_tile.dart';

/// The app's main tab: your rating, the two ways to start a duel, and your
/// recent match history, all on one page. This absorbed what used to be a
/// separate "Duel" tab — challenging someone and checking your own stats
/// were never really two different errands, so they don't need two
/// different screens either. It's the reason this tab sits raised and
/// centered in the bottom nav rather than as just another icon in the
/// row — see `AppShell`.
///
/// No app bar: the rating header *is* the header — a full-bleed arena field
/// running to all three top edges, with the two primary actions deliberately
/// straddling its lower slant so the eye is pulled across the boundary
/// instead of down a list of separate blocks.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// How far the action row is pulled up over the header's slanted edge.
  /// Subtracted again from the gap below it so nothing else shifts.
  static const double _overlap = 26;

  Future<void> _openChallengeSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final opponents = ref.read(opponentCandidatesProvider).value ?? [];
    final categoryId = ref.read(selectedCategoryIdProvider);

    if (opponents.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.duelNoOpponentsAvailable)));
      return;
    }
    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.duelSelectCategory)));
      return;
    }

    String? selectedOpponentId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.duelSelectOpponent, style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: selectedOpponentId,
                    items: opponents
                        .map((o) => DropdownMenuItem(value: o.uid, child: Text(o.displayName)))
                        .toList(),
                    onChanged: (value) => setState(() => selectedOpponentId = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: selectedOpponentId == null
                        ? null
                        : () async {
                            await ref
                                .read(duelControllerProvider.notifier)
                                .sendChallenge(toUserId: selectedOpponentId!, categoryId: categoryId);
                            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                          },
                    child: Text(l10n.homeChallengeFriend),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _quickMatch(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(duelControllerProvider.notifier)
        .joinQuickMatch(categoryId: ref.read(selectedCategoryIdProvider));
    final duelId = result['duelId'] as String?;
    if (duelId != null && context.mounted) {
      context.push(AppRoutes.duelIntroPath(duelId));
    }
    // If no duelId came back, `joinQuickMatch` has already recorded us as
    // queued (see `queuedLobbyIdProvider`) — `build` below watches that and
    // switches to the searching UI, then auto-navigates once
    // `openLobbyStreamProvider` reports a match.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final recentDuelsAsync = ref.watch(recentDuelsProvider);
    final myUid = ref.watch(currentUserIdProvider);
    final invites = ref.watch(incomingInvitesProvider);
    final duelState = ref.watch(duelControllerProvider);
    final queuedLobbyId = ref.watch(queuedLobbyIdProvider);
    final groupsAsync = ref.watch(categoryGroupsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final locale = ref.watch(currentUserProvider).value?.locale;
    final sentInviteId = ref.watch(sentInviteIdProvider);

    if (queuedLobbyId != null) {
      ref.listen(openLobbyStreamProvider(queuedLobbyId), (previous, next) {
        final duelId = next.value?.duelId;
        if (duelId == null) return;
        ref.read(duelControllerProvider.notifier).clearQueueAfterMatch();
        context.push(AppRoutes.duelIntroPath(duelId));
      });
    }

    // The other half of accepting a challenge: whoever *sent* it never
    // calls `respondToDuelChallenge` themselves, so they have no return
    // value to read a `duelId` off of. This watches their own sent invite
    // for the `duelId` `respondToDuelChallenge` stamps onto it and
    // navigates them in the instant their friend accepts.
    if (sentInviteId != null) {
      ref.listen(sentInviteStreamProvider(sentInviteId), (previous, next) {
        final duelId = next.value?.duelId;
        if (duelId == null) return;
        ref.read(duelControllerProvider.notifier).clearSentInviteAfterMatch();
        context.push(AppRoutes.duelIntroPath(duelId));
      });
    }

    // Quick-match search takes over the whole tab — waiting for an opponent
    // is already part of the duel, so the transition into the match should
    // feel continuous rather than like leaving a page behind.
    if (queuedLobbyId != null) {
      return Scaffold(
        backgroundColor: AppColors.arenaDark,
        body: _QuickMatchSearching(
          onCancel: () => ref.read(duelControllerProvider.notifier).cancelQuickMatch(),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(recentDuelsProvider);
          ref.invalidate(incomingInvitesProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const EmailVerificationBanner(),
            Stack(
              children: [
                userAsync.when(
                  data: (user) => ArenaRatingHeader(
                    displayName: user?.displayName ?? '',
                    elo: user?.elo ?? 0,
                    wins: user?.wins ?? 0,
                    losses: user?.losses ?? 0,
                  ),
                  loading: () => const SizedBox(
                    height: 240,
                    child: ColoredBox(color: AppColors.arenaDark),
                  ),
                  error: (_, _) => const SizedBox(
                    height: 240,
                    child: ColoredBox(color: AppColors.arenaDark),
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: _NotificationBell(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Transform.translate(
              offset: const Offset(0, -_overlap),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ResponsiveCenter(
                  child: Row(
                    children: [
                      Expanded(
                        child: SlabButton(
                          label: l10n.homeQuickMatch,
                          icon: Icons.bolt_rounded,
                          gradient: AppColors.primaryGradient,
                          background: AppColors.primary,
                          onPressed: duelState.isLoading ? null : () => _quickMatch(context, ref),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SlabButton(
                          label: l10n.homeChallengeFriend,
                          icon: Icons.people_alt_rounded,
                          background: AppColors.gold,
                          foreground: AppColors.onBrand,
                          onPressed: duelState.isLoading
                              ? null
                              : () => _openChallengeSheet(context, ref),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -_overlap),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: ResponsiveCenter(
                  child: invites.when(
                    data: (list) => Column(
                      children: list
                          .map(
                            (invite) => Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: InviteCard(
                                invite: invite,
                                onAccept: () async {
                                  final duelId = await ref
                                      .read(duelControllerProvider.notifier)
                                      .respondToChallenge(inviteId: invite.id, accept: true);
                                  if (duelId != null && context.mounted) {
                                    context.push(AppRoutes.duelIntroPath(duelId));
                                  }
                                },
                                onDecline: () => ref
                                    .read(duelControllerProvider.notifier)
                                    .respondToChallenge(inviteId: invite.id, accept: false),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Recent duels sits right under the rating/actions, above the
            // category catalog — the history that explains the rating you
            // just saw belongs next to it, not after the browse-and-pick
            // step you're about to do. Collapsed to a single condensed row
            // by default so it doesn't push the catalog below the fold; tap
            // it to expand into the full list.
            Transform.translate(
              offset: const Offset(0, -_overlap),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: ResponsiveCenter(
                  child: recentDuelsAsync.when(
                    data: (duels) {
                      if (duels.isEmpty || myUid == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.homeRecentDuels.toUpperCase(),
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _EmptyDuels(message: l10n.homeNoRecentDuels),
                          ],
                        );
                      }
                      return _RecentDuelsSection(
                        title: l10n.homeRecentDuels.toUpperCase(),
                        duels: duels,
                        myUid: myUid,
                        onOpenProfile: (uid) => context.push(AppRoutes.playerProfilePath(uid)),
                      );
                    },
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeRecentDuels.toUpperCase(),
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const SkeletonListTile(),
                      ],
                    ),
                    // Rendering nothing on error made a failing query
                    // indistinguishable from "no duels yet" — and a
                    // Firestore query that needs an undeployed composite
                    // index fails exactly here. Say so instead.
                    error: (_, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeRecentDuels.toUpperCase(),
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _EmptyDuels(message: l10n.commonError),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -_overlap),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: ResponsiveCenter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.duelSelectCategory.toUpperCase(),
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      groupsAsync.when(
                        data: (groups) => categoriesAsync.when(
                          data: (categories) => CategoryCatalog(
                            groups: groups,
                            categories: categories,
                            selectedCategoryId: selectedCategoryId,
                            locale: locale,
                            onSelect: (category) => ref
                                .read(selectedCategoryIdProvider.notifier)
                                .set(category.id == selectedCategoryId ? null : category.id),
                          ),
                          loading: () => const SkeletonList(itemCount: 2),
                          error: (_, _) => Text(l10n.commonError),
                        ),
                        loading: () => const SkeletonList(itemCount: 2),
                        error: (_, _) => Text(l10n.commonError),
                      ),
                    ],
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

/// Opens the notifications inbox. Overlaid on the arena header rather than
/// added as an `AppBar` — this screen deliberately has none (see the class
/// doc above) — so a single icon is the whole footprint this adds.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Badge(
      isLabelVisible: unreadCount > 0,
      label: Text('$unreadCount'),
      backgroundColor: AppColors.gold,
      textColor: AppColors.onBrand,
      child: IconButton(
        onPressed: () => context.push(AppRoutes.notifications),
        icon: const Icon(Icons.notifications_rounded, color: Colors.white),
        tooltip: l10n.notificationsTitle,
      ),
    );
  }
}

class _EmptyDuels extends StatelessWidget {
  const _EmptyDuels({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_kabaddi_rounded, size: 34, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// A collapsed strip of recent-duel result chips by default, expanding into
/// the full [RecentDuelTile] list on tap. Keeps the recent-duels section
/// compact enough to sit right under the rating/actions without pushing the
/// category catalog below the fold, while still making the full history one
/// tap away rather than a separate screen.
class _RecentDuelsSection extends StatefulWidget {
  const _RecentDuelsSection({
    required this.title,
    required this.duels,
    required this.myUid,
    required this.onOpenProfile,
  });

  final String title;
  final List<DuelModel> duels;
  final String myUid;
  final ValueChanged<String> onOpenProfile;

  @override
  State<_RecentDuelsSection> createState() => _RecentDuelsSectionState();
}

class _RecentDuelsSectionState extends State<_RecentDuelsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.labelSmall),
                      const SizedBox(height: AppSpacing.sm),
                      _RecentDuelsStrip(duels: widget.duels, myUid: widget.myUid),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              children: widget.duels
                  .map(
                    (d) => RecentDuelTile(
                      duel: d,
                      myUid: widget.myUid,
                      onTap: () => widget.onOpenProfile(d.opponentIdFor(widget.myUid)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// The collapsed preview: one small colored chip per recent duel, strung
/// together in a row — a result you can skim at a glance before deciding
/// whether it's worth expanding into the full list.
class _RecentDuelsStrip extends StatelessWidget {
  const _RecentDuelsStrip({required this.duels, required this.myUid});

  final List<DuelModel> duels;
  final String myUid;

  static const int _maxShown = 6;

  @override
  Widget build(BuildContext context) {
    final shown = duels.take(_maxShown).toList();
    final overflow = duels.length - shown.length;

    return Row(
      children: [
        for (final duel in shown) ...[
          _ResultChip(duel: duel, myUid: myUid),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (overflow > 0)
          Text(
            '+$overflow',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

/// One duel's outcome as a small colored circle — same win/loss/draw color
/// rule as [RecentDuelTile], just an icon instead of a name/score row so a
/// handful of these can sit in one line.
class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.duel, required this.myUid});

  final DuelModel duel;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final isFinished = duel.status == DuelStatus.completed;
    final isDraw = duel.winnerId == null || duel.winnerId!.isEmpty;
    final iWon = duel.winnerId == myUid;

    final (color, icon) = !isFinished
        ? (AppColors.textSecondary, Icons.schedule_rounded)
        : isDraw
        ? (AppColors.textSecondary, Icons.remove_rounded)
        : iWon
        ? (AppColors.success, Icons.check_rounded)
        : (AppColors.error, Icons.close_rounded);

    return Tooltip(
      message: duel.opponentDisplayNameFor(myUid),
      child: CircleAvatar(
        radius: 13,
        backgroundColor: color.withValues(alpha: 0.18),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

/// Shown while queued for a quick match. Takes over the whole tab as an
/// arena field rather than sitting inside the page: waiting for an opponent
/// is already part of the duel, and the transition into the match should
/// feel continuous rather than like leaving a list behind.
class _QuickMatchSearching extends StatelessWidget {
  const _QuickMatchSearching({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.arenaGradient)),
        ),
        const Positioned.fill(child: ClashBackdrop(opacity: 0.1)),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandedLoadingIndicator(message: l10n.duelSearchingMatch, onDark: true),
                  const SizedBox(height: AppSpacing.xxl),
                  SlabButton(
                    label: l10n.duelCancel,
                    expand: false,
                    background: AppColors.arenaRaised,
                    depthColor: AppColors.arenaDeep,
                    fontSize: 13,
                    onPressed: onCancel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
