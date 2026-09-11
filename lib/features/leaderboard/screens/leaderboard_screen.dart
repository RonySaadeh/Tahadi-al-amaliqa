import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/arena_panel.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../l10n/app_localizations.dart';
import '../leaderboard_controller.dart';
import '../widgets/leaderboard_podium.dart';
import '../widgets/leaderboard_row.dart';

/// Global ELO ranking, split into two very different registers: a podium for
/// the top three on an arena field, then a dense list for everyone else.
/// Tapping anyone opens a head-to-head sheet.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  void _showHeadToHead(BuildContext context, WidgetRef ref, LeaderboardEntryModel opponent) {
    final myUid = ref.read(currentUserIdProvider);
    if (myUid == null || myUid == opponent.uid) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final l10n = AppLocalizations.of(context)!;
            final theme = Theme.of(context);
            final recordAsync = ref.watch(headToHeadProvider((uidA: myUid, uidB: opponent.uid)));
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: recordAsync.when(
                data: (record) {
                  final wins = record?.winsFor(myUid) ?? 0;
                  final losses = record?.lossesFor(myUid) ?? 0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.leaderboardHeadToHead.toUpperCase(),
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        opponent.displayName,
                        style: theme.textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        textDirection: TextDirection.ltr,
                        children: [
                          _H2hStat(value: wins, color: AppColors.success),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Text('—', style: theme.textTheme.headlineMedium),
                          ),
                          _H2hStat(value: losses, color: AppColors.error),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const SkeletonListTile(),
                error: (_, _) => Text(l10n.commonError),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final leaderboardAsync = ref.watch(globalLeaderboardProvider);
    final myUid = ref.watch(currentUserIdProvider);

    return Scaffold(
      body: leaderboardAsync.when(
        loading: () => const SkeletonList(itemCount: 8),
        error: (_, _) => Center(child: Text(l10n.commonError)),
        data: (entries) {
          if (entries.isEmpty) {
            return _EmptyBoard(title: l10n.leaderboardTitle, message: l10n.leaderboardEmpty);
          }

          final rest = entries.skip(3).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ArenaPanel(
                  gradient: AppColors.arenaGradient,
                  slantHeight: 28,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    0,
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.leaderboardGlobal.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      LeaderboardPodium(
                        entries: entries,
                        myUid: myUid,
                        onTap: (entry) => _showHeadToHead(context, ref, entry),
                      ),
                    ],
                  ),
                ),
              ),
              if (rest.isNotEmpty)
                // Constrains and centers just the ranked list's cross axis —
                // the podium above stays a full-bleed arena field, but a
                // plain row list stretched edge-to-edge on a tablet/wide
                // browser window reads as an unfinished mobile layout.
                SliverConstrainedCrossAxis(
                  maxExtent: AppBreakpoints.contentMaxWidth,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.builder(
                      itemCount: rest.length,
                      itemBuilder: (context, index) {
                        final entry = rest[index];
                        return LeaderboardRow(
                          // +4: the podium already consumed ranks 1-3.
                          rank: index + 4,
                          entry: entry,
                          isMe: entry.uid == myUid,
                          onTap: () => _showHeadToHead(context, ref, entry),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _H2hStat extends StatelessWidget {
  const _H2hStat({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      textDirection: TextDirection.ltr,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(color: color),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.leaderboard_rounded, size: 44, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(title.toUpperCase(), style: theme.textTheme.displaySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
