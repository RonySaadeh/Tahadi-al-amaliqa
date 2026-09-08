import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../../duel/duel_controller.dart';
import '../home_controller.dart';
import '../widgets/elo_stat_card.dart';
import '../widgets/recent_duel_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserProvider);
    final recentDuelsAsync = ref.watch(recentDuelsProvider);
    final myUid = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(recentDuelsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            userAsync.when(
              data: (user) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeGreeting(user?.displayName ?? ''),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  EloStatCard(elo: user?.elo ?? 0, wins: user?.wins ?? 0, losses: user?.losses ?? 0),
                ],
              ),
              loading: () => const SkeletonListTile(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.duelLobby),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(l10n.homeChallengeFriend),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.duelLobby),
                    icon: const Icon(Icons.flash_on_rounded),
                    label: Text(l10n.homeQuickMatch),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.homeRecentDuels, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            recentDuelsAsync.when(
              data: (duels) {
                if (duels.isEmpty || myUid == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Text(l10n.homeNoRecentDuels, style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                return Column(
                  children: duels.map((d) => RecentDuelTile(duel: d, myUid: myUid)).toList(),
                );
              },
              loading: () => const SkeletonList(itemCount: 3),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
