import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/arena_panel.dart';
import '../../../core/widgets/branded_loading_indicator.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_router.dart';
import '../../home/home_controller.dart';
import '../live_duel_controller.dart';
import '../widgets/arena_hud.dart';
import '../widgets/duel_timer.dart';

/// Shown for exactly 10 seconds between a match being found and the first
/// question appearing — who you're about to play, and what each of you has
/// done in this category before, doesn't fit inside `LiveDuelScreen`'s own
/// opening beat, which is built entirely around a question that's already
/// ticking down. This screen owns that pause instead.
///
/// Purely a client-side delay: `duels/{duelId}` and its first round already
/// exist the instant this screen is pushed (see `createDuel.ts`), nothing
/// server-side distinguishes "just matched" from "round in progress" (see
/// `DuelStatus`). So this only holds the player here, then hands off to
/// `LiveDuelScreen` — which means round 1's own 15-second timer is already
/// running underneath this screen the whole time. A player sees roughly
/// `15 - 10 = 5` seconds left on round 1 the moment it appears; every later
/// round is unaffected, since its timer only starts once `LiveDuelScreen`
/// is already on screen watching for it.
class DuelIntroScreen extends ConsumerStatefulWidget {
  const DuelIntroScreen({super.key, required this.duelId});

  final String duelId;

  @override
  ConsumerState<DuelIntroScreen> createState() => _DuelIntroScreenState();
}

class _DuelIntroScreenState extends ConsumerState<DuelIntroScreen> {
  static const int _introSeconds = 10;

  // A field, not a call inside `build()`: `DuelTimer` keys its whole
  // countdown off this value, so it must stay fixed across this screen's
  // rebuilds (duel/user data streaming in) rather than resetting the clock
  // every time something else changes.
  final DateTime _introStartedAt = DateTime.now();

  void _enterDuel() {
    if (!mounted) return;
    context.go(AppRoutes.liveDuelPath(widget.duelId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final duelAsync = ref.watch(duelStreamProvider(widget.duelId));
    final myUid = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.arenaDark,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.arenaGradient)),
          ),
          const Positioned.fill(child: ClashBackdrop()),
          SafeArea(
            child: duelAsync.when(
              loading: () => const Center(child: BrandedLoadingIndicator(onDark: true)),
              error: (error, _) => Center(
                child: Text(
                  l10n.commonError,
                  style: theme.textTheme.titleMedium?.copyWith(color: AppColors.onArenaMuted),
                ),
              ),
              data: (duel) {
                if (duel == null || myUid == null) {
                  return Center(
                    child: Text(
                      l10n.commonError,
                      style: theme.textTheme.titleMedium?.copyWith(color: AppColors.onArenaMuted),
                    ),
                  );
                }

                final myName = myUid == duel.player1Id ? duel.player1DisplayName : duel.player2DisplayName;
                final opponentName = duel.opponentDisplayNameFor(myUid);
                final opponentId = duel.opponentIdFor(myUid);
                final myWins = ref.watch(currentUserProvider).value?.winsInCategory(duel.categoryId) ?? 0;
                final opponentWins =
                    ref.watch(userByIdProvider(opponentId)).value?.winsInCategory(duel.categoryId) ?? 0;

                return ResponsiveCenter(
                  maxWidth: 560,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          duel.categoryName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.gold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _DuelistCard(
                                name: myName,
                                categoryWins: myWins,
                                color: AppColors.playerOne,
                                winsLabel: l10n.duelIntroCategoryWinsLabel,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              child: ClashMark(size: 64),
                            ),
                            Expanded(
                              child: _DuelistCard(
                                name: opponentName,
                                categoryWins: opponentWins,
                                color: AppColors.playerTwo,
                                winsLabel: l10n.duelIntroCategoryWinsLabel,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          l10n.duelIntroMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                        ).animate().fadeIn(duration: 400.ms).moveY(begin: 8, end: 0),
                        const SizedBox(height: AppSpacing.lg),
                        DuelTimer(
                          roundStartedAt: _introStartedAt,
                          timeLimitSeconds: _introSeconds,
                          diameter: 96,
                          onTimeUp: _enterDuel,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DuelistCard extends StatelessWidget {
  const _DuelistCard({
    required this.name,
    required this.categoryWins,
    required this.color,
    required this.winsLabel,
  });

  final String name;
  final int categoryWins;
  final Color color;
  final String winsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Text(
            initial,
            style: theme.textTheme.displaySmall?.copyWith(color: color),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          trimmed.isEmpty ? '?' : trimmed,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$categoryWins',
          textDirection: TextDirection.ltr,
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 22, color: color),
        ),
        Text(
          winsLabel.toUpperCase(),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onArenaMuted, fontSize: 9),
        ),
      ],
    );
  }
}
