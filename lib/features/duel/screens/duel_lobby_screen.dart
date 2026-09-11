import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/arena_panel.dart';
import '../../../core/widgets/branded_loading_indicator.dart';
import '../../../core/widgets/slab_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../../home/home_controller.dart';
import '../duel_controller.dart';
import '../widgets/category_catalog.dart';
import '../widgets/invite_card.dart';

/// The duel hub: incoming challenges, a browsable category catalog, and the
/// "challenge a friend"/"quick match" actions. This is a tab in the bottom
/// nav — the actual gameplay happens on `LiveDuelScreen`, reached once a
/// duel exists.
///
/// Category selection happens up front, once, at the top of this screen —
/// both actions below then act on whichever category is currently selected
/// (or "any category" if none is), rather than each asking separately.
/// Picking a category before matching also makes quick match pair up
/// near-instantly, since it only has to find someone else waiting on that
/// same category instead of gambling on a random one (see
/// `functions/src/matchmaking/openLobby.ts`).
class DuelLobbyScreen extends ConsumerWidget {
  const DuelLobbyScreen({super.key});

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
      context.push(AppRoutes.liveDuelPath(duelId));
    }
    // If no duelId came back, `joinQuickMatch` has already recorded us as
    // queued (see `queuedLobbyIdProvider`) — `build` below watches that and
    // switches to the searching UI, then auto-navigates once
    // `openLobbyStreamProvider` reports a match.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final invites = ref.watch(incomingInvitesProvider);
    final duelState = ref.watch(duelControllerProvider);
    final queuedLobbyId = ref.watch(queuedLobbyIdProvider);
    final groupsAsync = ref.watch(categoryGroupsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final locale = ref.watch(currentUserProvider).value?.locale;

    if (queuedLobbyId != null) {
      ref.listen(openLobbyStreamProvider(queuedLobbyId), (previous, next) {
        final duelId = next.value?.duelId;
        if (duelId == null) return;
        ref.read(duelControllerProvider.notifier).clearQueueAfterMatch();
        context.push(AppRoutes.liveDuelPath(duelId));
      });
    }

    if (queuedLobbyId != null) {
      return Scaffold(
        backgroundColor: AppColors.arenaDark,
        body: _QuickMatchSearching(
          onCancel: () => ref.read(duelControllerProvider.notifier).cancelQuickMatch(),
        ),
      );
    }

    return Scaffold(
      body: duelState.isLoading
          ? const Center(child: BrandedLoadingIndicator())
          : Column(
              children: [
                ArenaPanel(
                  gradient: AppColors.arenaGradient,
                  slantHeight: 24,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.duelLobbyTitle.toUpperCase(),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.duelSelectCategory,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onArenaMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    children: [
                      invites.when(
                        data: (list) => Column(
                          children: list
                              .map(
                                (invite) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: InviteCard(
                                    invite: invite,
                                    onAccept: () async {
                                      final duelId = await ref
                                          .read(duelControllerProvider.notifier)
                                          .respondToChallenge(inviteId: invite.id, accept: true);
                                      if (duelId != null && context.mounted) {
                                        context.push(AppRoutes.liveDuelPath(duelId));
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
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => Text(l10n.commonError),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => Text(l10n.commonError),
                      ),
                    ],
                  ),
                ),
                // Pinned rather than trailing the scroll: the two things you
                // came here to do shouldn't be reachable only after scrolling
                // past the catalog.
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SlabButton(
                          label: l10n.homeQuickMatch,
                          icon: Icons.bolt_rounded,
                          gradient: AppColors.primaryGradient,
                          background: AppColors.primary,
                          onPressed: () => _quickMatch(context, ref),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SlabButton(
                          label: l10n.homeChallengeFriend,
                          icon: Icons.person_add_alt_1_rounded,
                          background: AppColors.gold,
                          foreground: AppColors.onBrand,
                          onPressed: () => _openChallengeSheet(context, ref),
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

/// Shown while queued for a quick match. Takes over the whole screen as an
/// arena field rather than sitting inside the lobby: waiting for an opponent
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
