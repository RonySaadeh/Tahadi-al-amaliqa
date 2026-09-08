import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/branded_loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../duel_controller.dart';
import '../widgets/invite_card.dart';

/// The duel hub: incoming challenges, "challenge a friend", and "quick
/// match". This is a tab in the bottom nav — the actual gameplay happens on
/// `LiveDuelScreen`, reached once a duel exists.
class DuelLobbyScreen extends ConsumerWidget {
  const DuelLobbyScreen({super.key});

  Future<void> _openChallengeSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final opponents = ref.read(opponentCandidatesProvider).value ?? [];
    final categories = ref.read(categoriesProvider).value ?? [];

    if (opponents.isEmpty || categories.isEmpty) return;

    String? selectedOpponentId;
    String? selectedCategoryId;

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
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.duelSelectCategory, style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (value) => setState(() => selectedCategoryId = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: (selectedOpponentId == null || selectedCategoryId == null)
                        ? null
                        : () async {
                            await ref
                                .read(duelControllerProvider.notifier)
                                .sendChallenge(toUserId: selectedOpponentId!, categoryId: selectedCategoryId!);
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
    final result = await ref.read(duelControllerProvider.notifier).joinQuickMatch();
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

    if (queuedLobbyId != null) {
      ref.listen(openLobbyStreamProvider(queuedLobbyId), (previous, next) {
        final duelId = next.value?.duelId;
        if (duelId == null) return;
        ref.read(duelControllerProvider.notifier).clearQueueAfterMatch();
        context.push(AppRoutes.liveDuelPath(duelId));
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.duelLobbyTitle)),
      body: queuedLobbyId != null
          ? _QuickMatchSearching(
              onCancel: () => ref.read(duelControllerProvider.notifier).cancelQuickMatch(),
            )
          : duelState.isLoading
          ? const Center(child: BrandedLoadingIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => _openChallengeSheet(context, ref),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(l10n.homeChallengeFriend),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _quickMatch(context, ref),
                  icon: const Icon(Icons.flash_on_rounded),
                  label: Text(l10n.homeQuickMatch),
                ),
              ],
            ),
    );
  }
}

/// Shown in place of the lobby list while queued for a quick match — the
/// same branded loading indicator used everywhere else, plus a cancel
/// button that leaves the queue.
class _QuickMatchSearching extends StatelessWidget {
  const _QuickMatchSearching({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandedLoadingIndicator(message: l10n.duelSearchingMatch),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(onPressed: onCancel, child: Text(l10n.duelCancel)),
        ],
      ),
    );
  }
}
