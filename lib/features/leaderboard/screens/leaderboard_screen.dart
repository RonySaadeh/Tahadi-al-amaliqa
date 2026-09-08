import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../l10n/app_localizations.dart';
import '../leaderboard_controller.dart';
import '../widgets/leaderboard_row.dart';

/// Global ELO ranking. Tapping a row opens a head-to-head sheet — this is
/// meant to feel like a sports-stats dashboard, not a plain settings list.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  void _showHeadToHead(BuildContext context, WidgetRef ref, LeaderboardEntryModel opponent) {
    final myUid = ref.read(currentUserIdProvider);
    if (myUid == null || myUid == opponent.uid) return;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final l10n = AppLocalizations.of(context)!;
            final recordAsync = ref.watch(headToHeadProvider((uidA: myUid, uidB: opponent.uid)));
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: recordAsync.when(
                data: (record) {
                  final wins = record?.winsFor(myUid) ?? 0;
                  final losses = record?.lossesFor(myUid) ?? 0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(opponent.displayName, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.leaderboardRecordAgainst(opponent.displayName, wins, losses),
                        style: Theme.of(context).textTheme.bodyLarge,
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
    final leaderboardAsync = ref.watch(globalLeaderboardProvider);
    final myUid = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.leaderboardTitle)),
      body: leaderboardAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(child: Text(l10n.leaderboardEmpty));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return LeaderboardRow(
                rank: index + 1,
                entry: entry,
                isMe: entry.uid == myUid,
                onTap: () => _showHeadToHead(context, ref, entry),
              );
            },
          );
        },
        loading: () => const SkeletonList(itemCount: 8),
        error: (_, _) => Center(child: Text(l10n.commonError)),
      ),
    );
  }
}
